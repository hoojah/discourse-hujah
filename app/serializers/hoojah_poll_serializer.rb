# frozen_string_literal: true

class HoojahPollSerializer < ApplicationSerializer
  attributes :id,
             :topic_id,
             :enabled,
             :vote_counts,
             :user_vote,
             :user_has_voted,
             :created_at

  def vote_counts
    object.vote_counts
  end

  def user_vote
    return nil unless scope.user
    vote = object.user_vote(scope.user)
    vote ? HoojahVoteSerializer.new(vote, scope: scope, root: false).as_json : nil
  end

  def user_has_voted
    return false unless scope.user
    object.user_has_voted?(scope.user)
  end

  def include_vote_counts?
    return true unless SiteSetting.hoojah_show_vote_counts_to_voters_only
    return true if scope.is_staff?
    user_has_voted
  end
end
