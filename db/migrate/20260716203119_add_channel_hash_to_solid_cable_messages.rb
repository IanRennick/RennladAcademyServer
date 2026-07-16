class AddChannelHashToSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    # ✅ Add the higher-performance big-integer hashing column Solid Cable v3 requires
    add_column :solid_cable_messages, :channel_hash, :bigint, null: false, default: 0

    # Speed up websocket channel matching lookups
    add_index :solid_cable_messages, :channel_hash
  end
end
