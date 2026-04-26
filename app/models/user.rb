class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Validate email format
  validates :email, format: URI::MailTo::EMAIL_REGEXP

  # User roles to allow different permissions
  enum :role, { user: 0, admin: 1, teacher: 2 }

  # Associate with Writing
  has_many :writings, dependent: :destroy

  # Associate with Comments
  has_many :comments, dependent: :destroy

  # Doorkeeper method to check password and return user
  def self.authenticate(email, password)
    user = User.find_for_authentication(email: email)
    user&.valid_password?(password) ? user : nil
  end
end
