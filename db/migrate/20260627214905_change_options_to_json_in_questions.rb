class ChangeOptionsToJsonInQuestions < ActiveRecord::Migration[8.1]
  def change
    # 1. Remove the rigid old columns
    remove_column :questions, :a, :string
    remove_column :questions, :b, :string
    remove_column :questions, :c, :string
    remove_column :questions, :d, :string

    # 2. Add the clean, dynamic JSON column
    # Rails automatically translates :json to the correct type for SQLite or Postgres
    add_column :questions, :options, :json, default: []
  end
end
