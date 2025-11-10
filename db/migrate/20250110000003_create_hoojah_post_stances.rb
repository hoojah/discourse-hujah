# frozen_string_literal: true

class CreateHoojahPostStances < ActiveRecord::Migration[7.0]
  def change
    create_table :hoojah_post_stances do |t|
      t.integer :post_id, null: false
      t.integer :hoojah_poll_id, null: false
      t.string :stance, null: false, limit: 20
      t.timestamps
    end

    add_index :hoojah_post_stances, :post_id, unique: true
    add_index :hoojah_post_stances, :hoojah_poll_id
    add_index :hoojah_post_stances, :stance
  end
end
