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
  after_update_commit { broadcast_update }

  # Helper to remove ourselves from list of Users
  scope :all_except, ->(user) { where.not(id: user) }

  # User roles to allow different permissions
  enum :role, { user: 0, admin: 1, teacher: 2 }

  enum :status, { offline: 0, away: 1, online: 2 }

  # Associate with Writing
  has_many :writings, dependent: :destroy

  # Associate with Comments
  has_many :comments, dependent: :destroy

  # Associate with Messages
  has_many :messages

  has_one_attached :avatar

  # Doorkeeper method to check password and return user
  def self.authenticate(email, password)
    user = User.find_for_authentication(email: email)
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

  # Handles complex, dynamic string array calculations in background space
  def update_tag_metrics(tag_names, was_correct)
    stat_record = user_tag_stat || create_user_tag_stat
    current_json = stat_record.stats_json.dup

    tag_names.each do |tag|
      current_json[tag] ||= { "done" => 0, "correct" => 0 }
      current_json[tag]["done"] += 1
      current_json[tag]["correct"] += 1 if was_correct
    end

    stat_record.update!(stats_json: current_json)
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
