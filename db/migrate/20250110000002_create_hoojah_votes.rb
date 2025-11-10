# frozen_string_literal: true

class CreateHoojahVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :hoojah_votes do |t|
      t.integer :hoojah_poll_id, null: false
      t.integer :user_id, null: false
      t.string :vote_type, null: false, limit: 20
      t.timestamps
    end

    add_index :hoojah_votes, [:hoojah_poll_id, :user_id], unique: true, name: 'index_hoojah_votes_on_poll_and_user'
    add_index :hoojah_votes, :user_id
    add_index :hoojah_votes, :vote_type
  end
end
