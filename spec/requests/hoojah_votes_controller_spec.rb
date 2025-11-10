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

      it 'rejects invalid vote types' do
        post '/hoojah/votes.json', params: { poll_id: poll.id, vote_type: 'invalid' }
        expect(response.status).to eq(400)
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
  end
end
