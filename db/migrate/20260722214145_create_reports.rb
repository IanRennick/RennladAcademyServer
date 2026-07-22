class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: true, foreign_key: true

      t.string :report_type, null: false
      t.text :description, null: false
      t.string :url
      t.string :status, null: false, default: "open" # open, investigating, resolved

      t.timestamps
    end
  end
end
