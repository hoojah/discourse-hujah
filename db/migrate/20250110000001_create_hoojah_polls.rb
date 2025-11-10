# frozen_string_literal: true

class CreateHoojahPolls < ActiveRecord::Migration[7.0]
  def change
    create_table :hoojah_polls do |t|
      t.integer :topic_id, null: false
      t.integer :created_by_user_id, null: false
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :hoojah_polls, :topic_id, unique: true
    add_index :hoojah_polls, :created_by_user_id
    add_index :hoojah_polls, :enabled
  end
end
