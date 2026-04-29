class AddDetailsToQuestion < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :prompt, :string
    add_column :questions, :keyword, :string
    add_column :questions, :a, :string
    add_column :questions, :b, :string
    add_column :questions, :c, :string
    add_column :questions, :d, :string
    add_column :questions, :kind, :integer
  end
end
