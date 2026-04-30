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

  # Doorkeeper method to check password and return user
  def self.authenticate(email, password)
    user = User.find_for_authentication(email: email)
    user&.valid_password?(password) ? user : nil
  end
end
