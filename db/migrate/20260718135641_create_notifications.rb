class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      # null: false guarantees a notification must have a target recipient and actor
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.datetime :read_at

      # JSONB acts as an open, infinitely scalable property map for message data parameters!
      t.jsonb :params, null: false, default: {}

      t.timestamps
    end

    # High-performance index to speed up lookups when checking unread notifications
    add_index :notifications, :read_at
  end
end
