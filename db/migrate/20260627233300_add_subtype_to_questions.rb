class AddSubtypeToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :subtype, :integer
  end
end
