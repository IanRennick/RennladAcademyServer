# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create Doorkeeper application
if Doorkeeper::Application.count.zero?
  Doorkeeper::Application.create(name: "Web Client", redirect_uri: "", scopes: "")
end

# Add admin user
User.create(name: "Rennick", email: "renn@example.com", password: "password", password_confirmation: "password", role: User.roles[:admin])

# Add test user
User.create(name: "Bob", email: "test@example.com", password: "password", password_confirmation: "password")

# Add test writings
10.times do |x|
  writing = Writing.create(user_id: User.second.id, body: "This is a test writing. I hope it's working.")

  5.times do |y|
    Comment.create(user_id: User.first.id, body: "This is a test comment", commentable: writing)
  end
end

# Add test multiple choice questions
10.times do |x|
  question = Question.create(kind: Question.kinds[:multiple_choice], main: "This is a test question?", answer: "Test answer", options: [ "Dublin", "Cork", "Galway", "Limerick" ])

  5.times do |y|
    Comment.create(user_id: User.first.id, body: "This is a test comment", commentable: question)
  end
end

# Add test open cloze questions
10.times do |x|
  question = Question.create(kind: Question.kinds[:open_cloze], main: "This is a test question?", answer: "Test answer")

  5.times do |y|
    Comment.create(user_id: User.first.id, body: "This is a test comment", commentable: question)
  end
end

# Add test word formation questions
10.times do |x|
  question = Question.create(kind: Question.kinds[:word_formation], main: "This is a test question?", answer: "Test answer", keyword: "Test word")

  5.times do |y|
    Comment.create(user_id: User.first.id, body: "This is a test comment", commentable: question)
  end
end

# Add test word formation questions
10.times do |x|
  question = Question.create(kind: Question.kinds[:sentence_cloze], main: "This is a test question?", answer: "Test answer", prompt: "This is a test prompt", keyword: "Test word")

  5.times do |y|
    Comment.create(user_id: User.first.id, body: "This is a test comment", commentable: question)
  end
end

# Test chat rooms
Room.create(name: "Test")
Room.create(name: "General")
Room.create(name: "Intro")
