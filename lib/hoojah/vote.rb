# frozen_string_literal: true

class HoojahVote < ActiveRecord::Base
  self.table_name = 'hoojah_votes'

  VALID_VOTE_TYPES = %w[agree neutral disagree].freeze

  belongs_to :hoojah_poll
  belongs_to :user

  validates :hoojah_poll_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :hoojah_poll_id }
  validates :vote_type, presence: true, inclusion: { in: VALID_VOTE_TYPES }

  after_commit :publish_vote_change

  private

  def publish_vote_change
    DiscourseEvent.trigger(
      :hoojah_vote_changed,
      hoojah_poll_id,
      hoojah_poll.topic_id
    )
  end
end
