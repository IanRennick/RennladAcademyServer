class FixSubmissionsAndDropWritings < ActiveRecord::Migration[8.1]
  def change
    # 1. Force drop the old ghost writings table if it's still lingering
    drop_table :writings, if_exists: true if table_exists?(:writings)

    # 2. Fix the submissions columns if they are stuck on student/teacher naming
    if table_exists?(:submissions)
      if column_exists?(:submissions, :student_id)
        rename_column :submissions, :student_id, :submitter_id
      end

      if column_exists?(:submissions, :teacher_id)
        rename_column :submissions, :teacher_id, :corrector_id
      end
    end
  end
end
