class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associate with Writing
  has_many :writings, dependent: :destroy

  # Associate with Comments
  has_many :comments, dependent: :destroy
end
