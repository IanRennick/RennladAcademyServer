class RenameQuestionTrackingColumns < ActiveRecord::Migration[8.1]
  def change
    # rename_column :table_name, :old_column_name, :new_column_name
    rename_column :questions, :attempted, :times_done
    rename_column :questions, :correct, :times_correct
  end
end
