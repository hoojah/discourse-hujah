# frozen_string_literal: true

class HoojahPoll < ActiveRecord::Base
  self.table_name = 'hoojah_polls'

  belongs_to :topic
  belongs_to :created_by_user, class_name: 'User', foreign_key: :created_by_user_id
  has_many :hoojah_votes, dependent: :destroy
  has_many :hoojah_post_stances, dependent: :destroy

  validates :topic_id, presence: true, uniqueness: true
  validates :created_by_user_id, presence: true

  # Get vote counts by type
  def vote_counts
    {
      agree: hoojah_votes.where(vote_type: 'agree').count,
      neutral: hoojah_votes.where(vote_type: 'neutral').count,
      disagree: hoojah_votes.where(vote_type: 'disagree').count,
      total: hoojah_votes.count
    }
  end

  # Get user's vote if exists
  def user_vote(user)
    return nil unless user
    hoojah_votes.find_by(user_id: user.id)
  end

  # Check if user has voted
  def user_has_voted?(user)
    return false unless user
    hoojah_votes.exists?(user_id: user.id)
  end

  # Get posts by stance
  def posts_by_stance(stance)
    return Post.none unless ['agree', 'neutral', 'disagree', 'none'].include?(stance)

    post_ids = if stance == 'none'
      # Posts in this topic without a stance
      topic.posts.where.not(id: hoojah_post_stances.pluck(:post_id)).pluck(:id)
    else
      hoojah_post_stances.where(stance: stance).pluck(:post_id)
    end

    Post.where(id: post_ids).order(:created_at)
  end
end
