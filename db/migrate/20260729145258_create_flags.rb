class CreateFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :flags do |t|
      t.integer :report_type
      t.text :body
      t.integer :status
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
