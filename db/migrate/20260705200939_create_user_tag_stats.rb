class CreateUserTagStats < ActiveRecord::Migration[8.1]
  def change
    create_table :user_tag_stats do |t|
      t.references :user, null: false, foreign_key: true
      t.json :stats_json, default: {}, null: false # Stores dynamic data maps

      t.timestamps
    end
  end
end
