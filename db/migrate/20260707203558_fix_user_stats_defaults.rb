class FixUserStatsDefaults < ActiveRecord::Migration[8.1]
  def change
    # Enforces that columns start at 0 at the database engine level instead of relying on model lifecycle callbacks
    change_column_default :user_stats, :times_done, from: nil, to: 0
    change_column_default :user_stats, :times_correct, from: nil, to: 0
  end
end
