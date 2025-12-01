# frozen_string_literal: true

require 'rails_helper'

describe DiscourseHoojah::VotesController do
  before do
    SiteSetting.hoojah_enabled = true
    SiteSetting.hoojah_min_trust_level_to_vote = 0
  end

  let(:user) { Fabricate(:user) }
  let(:topic) { Fabricate(:topic) }
  let(:poll) { Fabricate(:hoojah_poll, topic: topic, created_by_user: user) }

  describe '#create' do
    context 'when not logged in' do
      it 'returns 403' do
        post '/hoojah/votes.json', params: { poll_id: poll.id, vote_type: 'agree' }
        expect(response.status).to eq(403)
      end
    end

    context 'when logged in' do
      before { sign_in(user) }

      it 'creates a vote' do
        expect {
          post '/hoojah/votes.json', params: { poll_id: poll.id, vote_type: 'agree' }
        }.to change { HoojahVote.count }.by(1)

        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['hoojah_poll']['user_vote']['vote_type']).to eq('agree')
      end

      it 'returns complete poll data with vote counts' do
        # Add some existing votes
        HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'agree')
        HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'neutral')

        post '/hoojah/votes.json', params: { poll_id: poll.id, vote_type: 'disagree' }

        expect(response.status).to eq(200)
        json = JSON.parse(response.body)

        expect(json['hoojah_poll']['vote_counts']).to be_present
        expect(json['hoojah_poll']['vote_counts']['agree']).to eq(1)
        expect(json['hoojah_poll']['vote_counts']['neutral']).to eq(1)
        expect(json['hoojah_poll']['vote_counts']['disagree']).to eq(1)
        expect(json['hoojah_poll']['vote_counts']['total']).to eq(3)
        expect(json['hoojah_poll']['user_has_voted']).to eq(true)
      end

      it 'rejects invalid vote types' do
        post '/hoojah/votes.json', params: { poll_id: poll.id, vote_type: 'invalid' }
        expect(response.status).to eq(400)
      end

      it 'accepts all valid vote types' do
        %w[agree neutral disagree].each do |vote_type|
          voter = Fabricate(:user)
          sign_in(voter)

          post '/hoojah/votes.json', params: { poll_id: poll.id, vote_type: vote_type }
          expect(response.status).to eq(200)

          json = JSON.parse(response.body)
          expect(json['hoojah_poll']['user_vote']['vote_type']).to eq(vote_type)
        end
      end
    end

    context 'when trust level is insufficient' do
      before do
        SiteSetting.hoojah_min_trust_level_to_vote = 2
        sign_in(user)
      end

      it 'returns 403' do
        post '/hoojah/votes.json', params: { poll_id: poll.id, vote_type: 'agree' }
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#update' do
    let!(:vote) { Fabricate(:hoojah_vote, hoojah_poll: poll, user: user, vote_type: 'agree') }

    before { sign_in(user) }

    it 'updates existing vote' do
      put "/hoojah/votes/#{poll.id}.json", params: { vote_type: 'disagree' }
      expect(response.status).to eq(200)

      vote.reload
      expect(vote.vote_type).to eq('disagree')
    end

    it 'returns updated vote counts immediately' do
      # Add some other votes
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'agree')
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'neutral')

      put "/hoojah/votes/#{poll.id}.json", params: { vote_type: 'disagree' }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)

      # After changing from agree to disagree
      expect(json['hoojah_poll']['vote_counts']['agree']).to eq(1)
      expect(json['hoojah_poll']['vote_counts']['neutral']).to eq(1)
      expect(json['hoojah_poll']['vote_counts']['disagree']).to eq(1)
      expect(json['hoojah_poll']['vote_counts']['total']).to eq(3)
      expect(json['hoojah_poll']['user_vote']['vote_type']).to eq('disagree')
    end

    it 'allows changing vote multiple times' do
      put "/hoojah/votes/#{poll.id}.json", params: { vote_type: 'neutral' }
      expect(response.status).to eq(200)

      json = JSON.parse(response.body)
      expect(json['hoojah_poll']['user_vote']['vote_type']).to eq('neutral')

      put "/hoojah/votes/#{poll.id}.json", params: { vote_type: 'disagree' }
      expect(response.status).to eq(200)

      json = JSON.parse(response.body)
      expect(json['hoojah_poll']['user_vote']['vote_type']).to eq('disagree')
    end
  end

  describe '#destroy' do
    let!(:vote) { Fabricate(:hoojah_vote, hoojah_poll: poll, user: user, vote_type: 'agree') }

    before { sign_in(user) }

    it 'removes the vote' do
      expect {
        delete "/hoojah/votes/#{poll.id}.json"
      }.to change { HoojahVote.count }.by(-1)

      expect(response.status).to eq(200)
    end

    it 'returns updated poll data with user_has_voted as false' do
      # Add some other votes
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'neutral')

      delete "/hoojah/votes/#{poll.id}.json"

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)

      expect(json['hoojah_poll']['user_has_voted']).to eq(false)
      expect(json['hoojah_poll']['user_vote']).to be_nil
      expect(json['hoojah_poll']['vote_counts']['agree']).to eq(0)
      expect(json['hoojah_poll']['vote_counts']['neutral']).to eq(1)
      expect(json['hoojah_poll']['vote_counts']['total']).to eq(1)
    end
  end
end
