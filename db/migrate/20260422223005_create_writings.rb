class CreateWritings < ActiveRecord::Migration[8.0]
  def change
    create_table :writings do |t|
      t.text :body

      t.timestamps
    end
  end
end
