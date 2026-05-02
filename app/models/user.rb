class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validate email format
  validates :email, format: URI::MailTo::EMAIL_REGEXP

  # Add new user to list of users without needing to refresh page
  after_create_commit { broadcast_append_to "users" }

  # Helper to remove ourselves from list of Users
  scope :all_except, ->(user) { where.not(id: user) }

  # User roles to allow different permissions
  enum :role, { user: 0, admin: 1, teacher: 2 }

  # Associate with Writing
  has_many :writings, dependent: :destroy

  # Associate with Comments
  has_many :comments, dependent: :destroy

  # Associate with Messages
  has_many :messages

  has_one_attached :avatar

  after_create_commit :add_default_avatar, on: %i[create update]

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


  private
  def add_default_avatar
    return if avatar.attached?

    avatar.attach(
      io: File.open(Rails.root.join("app", "assets", "images", "default_avatar.jpg")),
      filename: "default_avatar.jpg",
      content_type: "image/jpg"
    )
  end
end
