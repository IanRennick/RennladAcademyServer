class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validate email format
  validates :email, format: URI::MailTo::EMAIL_REGEXP

  # Add new user to list of users without needing to refresh page
  after_create_commit :add_default_avatar, on: %i[create update]
  after_create_commit { broadcast_append_to "users" }
  after_commit :broadcast_update, on: :update
  
  # Helper to remove ourselves from list of Users
  scope :all_except, ->(user) { where.not(id: user) }

  # User roles to allow different permissions
  enum :role, { user: 0, admin: 1, teacher: 2 }

  enum :status, { offline: 0, away: 1, online: 2 }

  # Associations with writings, comments, messages
  has_many :writings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :messages
  has_many :user_histories, dependent: :destroy

  has_one_attached :avatar

  # Doorkeeper method to check password and return user
  def self.authenticate(login_credentials, password)
    # Passes the credentials directly into our new virtual lookup system
    user = User.find_for_database_authentication(login: login_credentials)
    user&.valid_password?(password) ? user : nil
  end

  def avatar_thumbnail
    avatar.variant(resize_to_limit: [ 150, 150 ]).processed
  end

  def chat_avatar
    avatar.variant(resize_to_limit: [ 50, 50 ]).processed
  end

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




  private
  def add_default_avatar
    return if avatar.attached?

    avatar.attach(
      io: File.open(Rails.root.join("app", "assets", "images", "default_avatar.jpg")),
      filename: "default_avatar.jpg",
      content_type: "image/jpg"
    )
  end

  def build_initial_tag_stat
    create_user_tag_stat(stats_json: {})
  end
end
