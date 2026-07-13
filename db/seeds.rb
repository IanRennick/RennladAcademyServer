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
User.create(username: "Rennick", email: "renn@example.com", password: "password", password_confirmation: "password", role: User.roles[:admin])

# Add test user
User.create(username: "Bob", email: "test@example.com", password: "password", password_confirmation: "password")

# Add levels
levels_data = [
  { name: "B1", initial_rating: 900,  description: "Intermediate language level. Can understand familiar matters." },
  { name: "B2", initial_rating: 1200, description: "Upper-Intermediate language level. Can understand complex texts." },
  { name: "C1", initial_rating: 1500, description: "Advanced language level. Can recognise implicit context meanings." },
  { name: "C2", initial_rating: 1800, description: "Proficiency language level. Can understand everything with total ease." }
]

levels = {}
levels_data.each do |data|
  level = Level.create!(
    name: data[:name],
    initial_rating: data[:initial_rating],
    description: data[:description]
  )
  levels[level.name] = level
end



# Add test writings
10.times do |x|
  writing = Writing.create(user_id: User.second.id, body: "This is a test writing. I hope it's working.")

  5.times do |y|
    Comment.create(user_id: User.first.id, body: "This is a test comment", commentable: writing)
  end
end



# Test chat rooms
Room.create(name: "Test")
Room.create(name: "General")
Room.create(name: "Intro")
