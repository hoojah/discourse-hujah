# frozen_string_literal: true

class HoojahPostStance < ActiveRecord::Base
  self.table_name = 'hoojah_post_stances'

  VALID_STANCES = %w[agree neutral disagree].freeze

  belongs_to :post
  belongs_to :hoojah_poll

  validates :post_id, presence: true, uniqueness: true
  validates :hoojah_poll_id, presence: true
  validates :stance, presence: true, inclusion: { in: VALID_STANCES }

  after_commit :publish_stance_change

  private

  def publish_stance_change
    MessageBus.publish(
      "/hoojah/topic/#{hoojah_poll.topic_id}",
      {
        type: 'hoojah_post_stance_updated',
        post_id: post_id,
        stance: stance
      }
    )
  end
end
