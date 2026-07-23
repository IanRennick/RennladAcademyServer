# app/models/user.rb
# =========================================================================
# SYSTEM MASTER ACCOUNT USER IDENTITY & PERMISSIONS MODEL
# - Integrates Devise authentication filters supporting dual username/email lookups
# - Handles ActiveStorage avatars, multi-dimensional score caching, and Elo snaps
# - Coordinates real-time ActionCable presence streams and badge milestones
# =========================================================================
class User < ApplicationRecord
  # --- Virtual Parameters ---
  attr_accessor :login

  # --- Devise Authentication Engine ---
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # --- Enum Configurations ---
  enum :role, { student: 0, admin: 1, teacher: 2 }
  enum :status, { offline: 0, away: 1, online: 2 }

  # --- ActiveStorage Attachments ---
  has_one_attached :avatar

  # --- Associations ---
  has_many :comments, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :user_histories, dependent: :destroy
  has_many :elo_snapshots, dependent: :destroy
  has_many :user_stats, dependent: :destroy
  has_one :user_tag_stat, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :reports, dependent: :destroy

  # Hook up submission logs split cleanly by role profiles
  has_many :student_submissions, class_name: "Submission", foreign_key: :submitter_id, dependent: :destroy
  has_many :corrections, class_name: "Submission", foreign_key: :corrector_id, dependent: :nullify

  # --- Lifecycle Callback Hooks ---
  after_create :build_initial_tag_stat
  after_create_commit { broadcast_append_to "users" }
  after_create_commit :send_welcome_email
  after_commit :broadcast_update_presence, on: :update

  # --- Validations ---
  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" }

  # --- Scopes Matrix ---
  scope :all_except, ->(user) { where.not(id: user) }

  # --- Class Level Devise / Doorkeeper Authenticators ---

  # Overwrites Devise lookup mechanics to handle BOTH usernames and emails interchangeably
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where([ "lower(username) = :value OR lower(email) = :value", { value: login.downcase } ]).first
    else
      where(conditions.to_h).first
    end
  end

  def self.authenticate(login_credentials, password)
    user = find_for_database_authentication(login: login_credentials)
    user&.valid_password?(password) ? user : nil
  end

  # --- Instance Level Core Utility Methods ---

  def avatar_initial
    (username.presence || "?").first.upcase
  end

  def status_to_css
    case status
    when "online"  then "bg-success"
    when "away"    then "bg-warning"
    when "offline" then "bg-dark"
    else "bg-dark"
    end
  end

  def broadcast_update_presence
    broadcast_replace_to "user_status", partial: "users/status", user: self
  end

  # --- JSONB Analytics & Gamification Engines ---

  # Updates individual tag analytics blocks inside the user's serialized JSONB payload
  def update_tag_metrics(tag_names, question_rating, was_correct)
    stat_record = user_tag_stat || create_user_tag_stat
    current_json = stat_record.stats_json.dup

    tag_names.each do |tag|
      current_json[tag] ||= { "done" => 0, "correct" => 0, "rating" => 1200 }

      new_user_tag_elo, _new_q_elo = EloCalculator.calculate(
        current_json[tag]["rating"],
        question_rating,
        was_correct,
        current_json[tag]["done"]
      )

      current_json[tag]["done"] += 1
      current_json[tag]["correct"] += 1 if was_correct
      current_json[tag]["rating"] = new_user_tag_elo
    end

    stat_record.update!(stats_json: current_json)
    check_and_award_achievements!
  end

  # Daily background archival snapshot script utilizing fast database upserts
  def capture_daily_snapshot
    stats_matrix = {}
    user_stats.where(stat_type: "kind").each do |stat|
      category_name = Question.kinds.key(stat.stat_key)
      stats_matrix[category_name] = stat.rating if category_name
    end

    elo_snapshots.upsert(
      {
        rating: rating,
        recorded_on: Date.current,
        category_ratings: stats_matrix
      },
      unique_by: [ :user_id, :recorded_on ]
    )
  end

  # Scans user milestones and dispatches whitelisted polymorphic notifications
  def check_and_award_achievements!
    total_answered = user_stats.where(stat_type: "kind").sum(:times_done)

    Badge.where(milestone_type: "total_questions").where.not(id: badges.pluck(:id)).each do |badge|
      if total_answered >= badge.milestone_threshold
        user_badges.create!(badge: badge)

        # FIXED: Event type string shifted to whitelisted 'badge_unlock' to pass notification constraints!
        Notification.create!(
          recipient: self,
          actor: User.where(role: :admin).first || self,
          event_type: "badge_unlock",
          params: {
            "message" => "unlocked the '#{badge.name}' achievement medal! 🏆",
            "text_snippet" => badge.description,
            "url" => "/stats"
          }
        )
      end
    end
  end

  private

  def build_initial_tag_stat
    create_user_tag_stat(stats_json: {})
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
    notify_admins_of_signup
  end

  def notify_admins_of_signup
    admins = User.where(role: :admin)
    return if admins.empty?

    admins.each do |admin_user|
      next if admin_user.id == id

      Notification.create!(
        recipient: admin_user,
        actor: self,
        event_type: "new_user_signup",
        params: {
          "message" => "joined Rennlad Academy as a new student!",
          "email" => email,
          "url" => "/u/#{id}"
        }
      )
    end
  end
end
