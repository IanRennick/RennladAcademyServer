json.extract! question, :id, :main, :answer, :attempted, :correct, :created_at, :updated_at
json.url question_url(question, format: :json)
