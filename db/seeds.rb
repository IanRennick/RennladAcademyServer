# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 1. ✅ PROTECT DOORKEEPER: Uses find_or_create_by! to completely protect your active React token keys
puts "🔑 Checking Production Doorkeeper Token Client..."
Doorkeeper::Application.find_or_create_by!(name: "React Frontend App Client") do |app|
  app.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
  app.confidential = false
end

# 2. ✅ PROTECT ADMIN: Uses find_or_initialize_by to prevent email/username unique crashes
puts "👤 Checking Admin User Accounts..."
admin = User.find_or_initialize_by(email: "renn@example.com")
if admin.new_record?
  admin.username = "Rennick"
  admin.password = "password" # Make sure to change this to a secure string on your live app screen!
  admin.password_confirmation = "password"
  admin.role = User.roles[:admin]
  admin.save!
  puts "👤 Created master admin account: Rennick"
else
  puts "👤 Admin account already exists. Skipping."
end

# 3. ✅ PROTECT CEFR LEVELS: Uses find_or_initialize_by so ratings and descriptions are never wiped out
puts "🎯 Checking CEFR Level baseline tiers..."
levels_data = [
  { name: "B1", initial_rating: 900,  description: "Intermediate language level. Can understand familiar matters." },
  { name: "B2", initial_rating: 1200, description: "Upper-Intermediate language level. Can understand complex texts." },
  { name: "C1", initial_rating: 1500, description: "Advanced language level. Can recognise implicit context meanings." },
  { name: "C2", initial_rating: 1800, description: "Proficiency language level. Can understand everything with total ease." }
]

levels_data.each do |data|
  level = Level.find_or_initialize_by(name: data[:name])
  if level.new_record?
    level.initial_rating = data[:initial_rating]
    level.description = data[:description]
    level.save!
    puts "🎯 Created CEFR Tier: #{data[:name]}"
  else
    puts "🎯 CEFR Tier #{data[:name]} already exists. Skipping."
  end
end

puts "🚀 Seeding master platform Achievement Badges..."

badges_data = [
  {
    name: "Grammar Cadet",
    description: "Submit your very first grammar or vocabulary puzzle attempt.",
    icon: "🌱",
    milestone_type: "total_questions",
    milestone_threshold: 1
  },
  {
    name: "Consistent Scholar",
    description: "Complete a total of 25 question puzzles on the training hub.",
    icon: "📚",
    milestone_type: "total_questions",
    milestone_threshold: 25
  },
  {
    name: "Puzzle Veteran",
    description: "Cross a milestone of 100 overall question puzzle submissions.",
    icon: "🧠",
    milestone_type: "total_questions",
    milestone_threshold: 100
  },
  {
    name: "Century Master",
    description: "Achieve the massive milestone of 500 completed puzzle attempts.",
    icon: "👑",
    milestone_type: "total_questions",
    milestone_threshold: 500
  },
  {
    name: "Grandmaster League",
    description: "An elite tier badge unlocked for answering 1,000 question puzzles.",
    icon: "🔥",
    milestone_type: "total_questions",
    milestone_threshold: 1000
  }
]

badges_data.each do |badge_attrs|
  badge = Badge.find_or_initialize_by(name: badge_attrs[:name])
  badge.update!(badge_attrs)
end

puts "✨ Successfully loaded #{Badge.count} authoritative achievement medals into the database registry!"

puts "🎉 Safe Seeds Check Execution Complete!"
