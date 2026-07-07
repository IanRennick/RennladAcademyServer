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

# Add test multiple choice questions
Question.create(level: levels["B2"], kind: Question.kinds[:multiple_choice], subtype: Question.subtypes[:mc_phrasal_verb], main: "On the night of 21 October 1931, millions of Americans * part in a coast-to-coast ceremony to commemorate the passing of Thomas Edison.", answers: [ "took" ], options: [ "joined", "held", "took", "were" ], tag_list: "phrasal, phrasal_take")
Question.create(level: levels["B2"], kind: Question.kinds[:multiple_choice], subtype: Question.subtypes[:mc_collocation], main: "Few inventors have * such an impact on everyday life as Thomas Edison.", answers: [ "had" ], options: [ "put", "had", "served", "set" ], tag_list: "collocation_have, collocation")



# Add test open cloze questions
Question.create(level: levels["B2"], kind: Question.kinds[:open_cloze], subtype: Question.subtypes[:oc_determiner], main: "The scenery still amazes visitors to * city of Vancouver today.", answers: [ "the" ], tag_list: "determiner, determiner_noun_of_noun",)
Question.create(level: levels["B2"], kind: Question.kinds[:open_cloze], subtype: Question.subtypes[:oc_preposition], main: "Tourists are usually directed to a beach about ten minutes * the city centre.", answers: [ "from" ], tag_list: "preposition, preposition_travel")



# Add test word formation questions
Question.create(level: levels["B2"], kind: Question.kinds[:word_formation], subtype: Question.subtypes[:wf_noun], main: "Naturally, the * of the stunt performer is of the utmost importance.", answers: [ "safety" ], keyword: "safe", tag_list: "determiner_noun_of_noun, abstract_noun")
Question.create(level: levels["B2"], kind: Question.kinds[:word_formation], subtype: Question.subtypes[:wf_adverb], main: "The work is * demanding,.", answers: [ "incredibly" ], keyword: "incredible", tag_list: "adverb, adverb_degree")


# Add test word formation questions
Question.create(level: levels["B2"], kind: Question.kinds[:sentence_cloze], subtype: Question.subtypes[:sc_reported_speech], main: "Our teacher * in front of the computer for too long.", answers: [ "warned us not to sit" ], prompt: "'Don't sit in front of the computer for too long,' our teacher told us.", keyword: "warned", tag_list: "reporting_verb, reported_speech")
Question.create(level: levels["B2"], kind: Question.kinds[:sentence_cloze], subtype: Question.subtypes[:sc_hypothetical], main: "I wish that * more sport when I was at school.", answers: [ "I could have done" ], prompt: "It's a pity we didn't do more sport when I was at school.", keyword: "could", tag_list: "wishes, hypothetical, hypothetical_past")


# Test chat rooms
Room.create(name: "Test")
Room.create(name: "General")
Room.create(name: "Intro")
