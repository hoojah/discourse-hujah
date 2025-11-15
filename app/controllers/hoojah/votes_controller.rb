# frozen_string_literal: true

module DiscourseHoojah
  class VotesController < ::ApplicationController
    requires_plugin 'discourse-hujah'

    before_action :ensure_logged_in
    before_action :find_poll

    def create
      raise Discourse::InvalidAccess.new unless guardian.can_vote_hoojah?(@poll)

      vote_type = params.require(:vote_type)
      raise Discourse::InvalidParameters.new(:vote_type) unless HoojahVote::VALID_VOTE_TYPES.include?(vote_type)

      # Find or create vote
      vote = HoojahVote.find_or_initialize_by(
        hoojah_poll_id: @poll.id,
        user_id: current_user.id
      )
      vote.vote_type = vote_type
      vote.save!

      # Reload poll to get fresh vote counts
      @poll.reload
      render_serialized(@poll, HoojahPollSerializer, root: 'hoojah_poll')
    end

    def update
      raise Discourse::InvalidAccess.new unless guardian.can_vote_hoojah?(@poll)

      vote = HoojahVote.find_by(hoojah_poll_id: @poll.id, user_id: current_user.id)
      raise Discourse::NotFound unless vote

      vote_type = params.require(:vote_type)
      raise Discourse::InvalidParameters.new(:vote_type) unless HoojahVote::VALID_VOTE_TYPES.include?(vote_type)

      vote.update!(vote_type: vote_type)

      # Reload poll to get fresh vote counts
      @poll.reload
      render_serialized(@poll, HoojahPollSerializer, root: 'hoojah_poll')
    end

    def destroy
      vote = HoojahVote.find_by(hoojah_poll_id: @poll.id, user_id: current_user.id)

      if vote
        vote.destroy!
        # Reload poll to get fresh vote counts
        @poll.reload
        render_serialized(@poll, HoojahPollSerializer, root: 'hoojah_poll')
      else
        render json: failed_json, status: 404
      end
    end

    private

    def find_poll
      @poll = HoojahPoll.find_by(id: params[:poll_id])
      raise Discourse::NotFound unless @poll
    end
  end
end
