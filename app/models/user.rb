class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validate email format
  validates :email, format: URI::MailTo::EMAIL_REGEXP

  # Add new user to list of users without needing to refresh page
  after_create_commit { broadcast_append_to "users" }
  after_commit :broadcast_update, on: :update
  # ✅ AUTOMATED EMAIL HOOK: Fires completely in the background on account initialization
  after_create_commit :send_welcome_email

  # Helper to remove ourselves from list of Users
  scope :all_except, ->(user) { where.not(id: user) }

  # User roles to allow different permissions
  enum :role, { student: 0, admin: 1, teacher: 2 }
  enum :status, { offline: 0, away: 1, online: 2 }

  # Associations with writings, comments, messages
  has_many :writings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :messages
  has_many :user_histories, dependent: :destroy
  has_many :elo_snapshots, dependent: :destroy
  has_one_attached :avatar
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy

  # Doorkeeper method to check password and return user
  def self.authenticate(login_credentials, password)
    # Passes the credentials directly into our new virtual lookup system
    user = User.find_for_database_authentication(login: login_credentials)
    user&.valid_password?(password) ? user : nil
  end

  def avatar_initial
    (username.presence || "?").first.upcase
  end

  # Keep these as fallback handles so nothing breaks if called elsewhere
  def avatar_thumbnail; ""; end
  def chat_avatar; ""; end

  def broadcast_update
    broadcast_replace_to "user_status", partial: "users/status", user: self
  end

  def status_to_css
    case status
    when "online"
      "bg-success"
    when "away"
      "bg-warning"
    when "offline"
      "bg-dark"
    else
      "bg-dark"
    end
  end

  # Stats
  has_many :user_stats, dependent: :destroy
  has_one :user_tag_stat, dependent: :destroy

  # Automatically hook an empty scoreboard setup right on signup
  after_create :build_initial_tag_stat

  def update_tag_metrics(tag_names, question_rating, was_correct)
    stat_record = user_tag_stat || create_user_tag_stat
    current_json = stat_record.stats_json.dup

    tag_names.each do |tag|
      # Initialize default data structure including a starting Elo of 1200
      current_json[tag] ||= { "done" => 0, "correct" => 0, "rating" => 1200 }

      # 1. Run the Elo adjustment exclusively for this specific tag
      new_user_tag_elo, _new_q_elo = EloCalculator.calculate(
        current_json[tag]["rating"],
        question_rating,
        was_correct,
        current_json[tag]["done"]
      )

      # 2. Commit metrics back to the memory block
      current_json[tag]["done"] += 1
      current_json[tag]["correct"] += 1 if was_correct
      current_json[tag]["rating"] = new_user_tag_elo
    end

    stat_record.update!(stats_json: current_json)
  end

  # Create a virtual memory attribute for handling incoming login credentials
  attr_accessor :login

  # Enforce explicit handle validations (No spaces allowed, letters/numbers/underscores only)
  validates :username, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" }

  # Overwrite Devise's lookup query tool to handle BOTH usernames and emails interchangeably
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      # This performs a secure case-insensitive OR lookup inside the database engine
      where(conditions.to_h).where([ "lower(username) = :value OR lower(email) = :value", { value: login.downcase } ]).first
    else
      where(conditions.to_h).first
    end
  end

  # ✅ V2 HISTORY TIMELINE SNAPSHOT ENGINE (UPGRADED)
  # Captures the user's global rating AND category breakdowns for today's unique date
  def capture_daily_snapshot
    # 1. Gather a clean summary map of their active category Elo metrics
    stats_matrix = {}
    user_stats.where(stat_type: "kind").each do |stat|
      category_name = Question.kinds.key(stat.stat_key)
      stats_matrix[category_name] = stat.rating if category_name
    end

    # 2. UPSERT MATRIX RECORDS
    elo_snapshots.upsert(
      {
        rating: self.rating,
        recorded_on: Date.current,
        category_ratings: stats_matrix # ✅ Saves category breakdowns dynamically for your charts!
      },
      unique_by: [ :user_id, :recorded_on ]
    )
  end

  private

  def build_initial_tag_stat
    create_user_tag_stat(stats_json: {})
  end

  def send_welcome_email
    # .deliver_later tells Rails 8 to offload the mailer task to Solid Queue asynchronously,
    # ensuring your student's user registration experience stays lightning fast!
    UserMailer.welcome_email(self).deliver_later
    # ✅ NEW SPRINT TRIGGER: Notify Admins immediately of the new signup!
    notify_admins_of_signup
  end

  def notify_admins_of_signup
    # 1. Locate all administrative accounts currently registered on the server
    admins = User.where(role: :admin)
    return if admins.empty?

    # 2. Loop through the admin pool and stamp a custom polymorphic row entry for each
    admins.each do |admin_user|
      # Safety guard clause: skip notifying yourself if you are an admin creating a user
      next if admin_user.id == self.id

      Notification.create!(
        recipient: admin_user,
        actor: self, # The brand-new student is the active actor who triggered the event
        event_type: "new_user_signup",
        params: {
          "message" => "joined Rennlad Academy as a new student!",
          "email" => self.email,
          "url" => "/u/#{self.id}" # Direct deep link path hook to their upgraded analytics profile
        }
      )
    end
  end
end
