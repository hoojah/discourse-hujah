# frozen_string_literal: true

require 'rails_helper'

describe HoojahPollSerializer do
  before do
    SiteSetting.hoojah_enabled = true
    SiteSetting.hoojah_show_vote_counts_to_voters_only = false
  end

  let(:user) { Fabricate(:user) }
  let(:voter) { Fabricate(:user) }
  let(:topic) { Fabricate(:topic, user: user) }
  let(:poll) { Fabricate(:hoojah_poll, topic: topic, created_by_user: user) }

  def serialized_poll(poll, viewing_user = nil)
    scope = Guardian.new(viewing_user)
    HoojahPollSerializer.new(poll, scope: scope, root: false).as_json
  end

  describe 'basic attributes' do
    it 'includes all basic attributes' do
      json = serialized_poll(poll)

      expect(json[:id]).to eq(poll.id)
      expect(json[:topic_id]).to eq(topic.id)
      expect(json[:enabled]).to eq(true)
      expect(json[:created_at]).to be_present
    end
  end

  describe '#vote_counts' do
    before do
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'agree')
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'agree')
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'neutral')
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'disagree')
    end

    it 'returns correct vote counts' do
      json = serialized_poll(poll)

      expect(json[:vote_counts][:agree]).to eq(2)
      expect(json[:vote_counts][:neutral]).to eq(1)
      expect(json[:vote_counts][:disagree]).to eq(1)
      expect(json[:vote_counts][:total]).to eq(4)
    end

    context 'when vote_counts_to_voters_only is enabled' do
      before do
        SiteSetting.hoojah_show_vote_counts_to_voters_only = true
      end

      it 'hides vote_counts for anonymous users' do
        json = serialized_poll(poll, nil)
        expect(json[:vote_counts]).to be_nil
      end

      it 'hides vote_counts for non-voters' do
        non_voter = Fabricate(:user)
        json = serialized_poll(poll, non_voter)
        expect(json[:vote_counts]).to be_nil
      end

      it 'shows vote_counts for voters' do
        HoojahVote.create!(hoojah_poll: poll, user: voter, vote_type: 'agree')
        poll.reload
        json = serialized_poll(poll, voter)
        expect(json[:vote_counts]).to be_present
        expect(json[:vote_counts][:total]).to eq(5)
      end

      it 'shows vote_counts for staff' do
        admin = Fabricate(:admin)
        json = serialized_poll(poll, admin)
        expect(json[:vote_counts]).to be_present
      end
    end
  end

  describe '#user_vote' do
    it 'returns nil for anonymous users' do
      json = serialized_poll(poll, nil)
      expect(json[:user_vote]).to be_nil
    end

    it 'returns nil when user has not voted' do
      json = serialized_poll(poll, voter)
      expect(json[:user_vote]).to be_nil
    end

    it 'returns vote data when user has voted' do
      vote = HoojahVote.create!(hoojah_poll: poll, user: voter, vote_type: 'disagree')
      poll.reload
      json = serialized_poll(poll, voter)

      expect(json[:user_vote]).to be_present
      expect(json[:user_vote][:vote_type]).to eq('disagree')
      expect(json[:user_vote][:id]).to eq(vote.id)
    end
  end

  describe '#user_has_voted' do
    it 'returns false for anonymous users' do
      json = serialized_poll(poll, nil)
      expect(json[:user_has_voted]).to eq(false)
    end

    it 'returns false when user has not voted' do
      json = serialized_poll(poll, voter)
      expect(json[:user_has_voted]).to eq(false)
    end

    it 'returns true when user has voted' do
      HoojahVote.create!(hoojah_poll: poll, user: voter, vote_type: 'agree')
      poll.reload
      json = serialized_poll(poll, voter)

      expect(json[:user_has_voted]).to eq(true)
    end
  end
end
