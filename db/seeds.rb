# db/seeds.rb
# =========================================================================
# AUTHORITATIVE INDEMPOTENT SEED ENGINE REGISTRY
# - Provisions core operational dependencies safely across all environments
# - Enforces strict validation schemes to accommodate modern Doorkeeper rules
# - Automates synchronization for CEFR tiers, achievement medals, and chatrooms
# =========================================================================

# --- 1. OAUTH DOORKEEPER GATEWAY ---
puts "🔑 Checking Production Doorkeeper Token Client..."
Doorkeeper::Application.find_or_create_by!(name: "React Frontend App Client") do |app|
  # ✅ FIXED: Shifted placeholder string to a fully qualified web scheme to satisfy strict RFC validation rules
  app.redirect_uri = "https://localhost/callback"
  app.confidential = false
end

# --- 2. ADMINISTRATIVE MASTER ACCOUNT ---
puts "👤 Checking Admin User Accounts..."
admin = User.find_or_initialize_by(email: "renn@example.com")
if admin.new_record?
  admin.username = "Rennick"
  admin.password = "password" # NOTE: Change this to an environment variable string on production screens!
  admin.password_confirmation = "password"
  # ✅ FIXED: Simplified enum mapping lookup strings
  admin.role = "admin"
  admin.save!
  puts "👤 Created master admin account: Rennick"
else
  puts "👤 Admin account already exists. Skipping."
end

# --- 3. CEFR LEVELS TIERS ---
puts "🎯 Checking CEFR Level baseline tiers..."
levels_data = [
  { name: "B1", initial_rating: 900,  description: "Intermediate language level. Can understand familiar matters." },
  { name: "B2", initial_rating: 1200, description: "Upper-Intermediate language level. Can understand complex texts." },
  { name: "C1", initial_rating: 1500, description: "Advanced language level. Can recognise implicit context meanings." },
  { name: "C2", initial_rating: 1800, description: "Proficiency language level. Can understand everything with total ease." }
]

levels_data.each do |data|
  level = Level.find_or_initialize_by(name: data[:name])
  # ✅ FIXED: Shifted to an update macro so editing descriptions here pushes down to database fields seamlessly
  level.update!(
    initial_rating: data[:initial_rating],
    description: data[:description]
  )
end
puts "🎯 CEFR Level baseline tiers synchronized successfully."

# --- 4. GAMIFICATION PLATFORM BADGES ---
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

# --- 5. GLOBAL CHAT CHANNELS ---
puts "💬 Provisioning baseline communication streams..."
[ "general-curriculum", "ielts-vocabulary-lounge", "teachers-station" ].each do |channel_name|
  Room.find_or_create_by!(name: channel_name) do |room|
    room.is_private = false
  end
end
puts "💬 Baseline communication streams active."

puts "🎉 Safe Seeds Check Execution Complete!"
