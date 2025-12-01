# frozen_string_literal: true

require 'rails_helper'

describe DiscourseHoojah::PollsController do
  before do
    SiteSetting.hoojah_enabled = true
    SiteSetting.hoojah_allow_topic_creators_enable = true
  end

  let(:user) { Fabricate(:user) }
  let(:admin) { Fabricate(:admin) }
  let(:topic) { Fabricate(:topic, user: user) }

  describe '#create' do
    context 'when not logged in' do
      it 'returns 403' do
        post '/hoojah/polls.json', params: { topic_id: topic.id }
        expect(response.status).to eq(403)
      end
    end

    context 'when logged in as topic creator' do
      before { sign_in(user) }

      it 'creates a poll' do
        expect {
          post '/hoojah/polls.json', params: { topic_id: topic.id }
        }.to change { HoojahPoll.count }.by(1)

        expect(response.status).to eq(200)
        json = JSON.parse(response.body)
        expect(json['hoojah_poll']['topic_id']).to eq(topic.id)
      end

      it 'returns poll with empty vote counts' do
        post '/hoojah/polls.json', params: { topic_id: topic.id }

        json = JSON.parse(response.body)
        expect(json['hoojah_poll']['vote_counts']['agree']).to eq(0)
        expect(json['hoojah_poll']['vote_counts']['neutral']).to eq(0)
        expect(json['hoojah_poll']['vote_counts']['disagree']).to eq(0)
        expect(json['hoojah_poll']['vote_counts']['total']).to eq(0)
        expect(json['hoojah_poll']['user_has_voted']).to eq(false)
      end

      it 're-enables existing disabled poll' do
        existing_poll = HoojahPoll.create!(topic: topic, created_by_user: user, enabled: false)

        expect {
          post '/hoojah/polls.json', params: { topic_id: topic.id }
        }.not_to change { HoojahPoll.count }

        expect(response.status).to eq(200)
        existing_poll.reload
        expect(existing_poll.enabled).to eq(true)
      end
    end

    context 'when logged in as admin' do
      before { sign_in(admin) }

      it 'creates a poll' do
        expect {
          post '/hoojah/polls.json', params: { topic_id: topic.id }
        }.to change { HoojahPoll.count }.by(1)

        expect(response.status).to eq(200)
      end
    end

    context 'when logged in as different user' do
      before do
        SiteSetting.hoojah_allow_topic_creators_enable = true
        sign_in(Fabricate(:user))
      end

      it 'returns 403' do
        post '/hoojah/polls.json', params: { topic_id: topic.id }
        expect(response.status).to eq(403)
      end
    end

    context 'when topic creators cannot enable' do
      before do
        SiteSetting.hoojah_allow_topic_creators_enable = false
        sign_in(user)
      end

      it 'returns 403 for topic creator' do
        post '/hoojah/polls.json', params: { topic_id: topic.id }
        expect(response.status).to eq(403)
      end
    end

    context 'when hoojah is disabled globally' do
      before do
        SiteSetting.hoojah_enabled = false
        sign_in(user)
      end

      it 'returns 403' do
        post '/hoojah/polls.json', params: { topic_id: topic.id }
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#destroy' do
    let!(:poll) { Fabricate(:hoojah_poll, topic: topic, created_by_user: user) }

    context 'when logged in as topic creator' do
      before { sign_in(user) }

      it 'disables the poll' do
        delete "/hoojah/polls/#{topic.id}.json"
        expect(response.status).to eq(200)

        poll.reload
        expect(poll.enabled).to eq(false)
      end

      it 'preserves existing votes when disabled' do
        HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'agree')
        HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'neutral')

        expect {
          delete "/hoojah/polls/#{topic.id}.json"
        }.not_to change { HoojahVote.count }

        poll.reload
        expect(poll.enabled).to eq(false)
        expect(poll.votes.count).to eq(2)
      end
    end

    context 'when logged in as admin' do
      before { sign_in(admin) }

      it 'disables the poll' do
        delete "/hoojah/polls/#{topic.id}.json"
        expect(response.status).to eq(200)

        poll.reload
        expect(poll.enabled).to eq(false)
      end
    end

    context 'when logged in as different user' do
      before { sign_in(Fabricate(:user)) }

      it 'returns 403' do
        delete "/hoojah/polls/#{topic.id}.json"
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#show' do
    let!(:poll) { Fabricate(:hoojah_poll, topic: topic, created_by_user: user) }

    it 'returns poll data without authentication' do
      get "/hoojah/polls/#{topic.id}.json"
      expect(response.status).to eq(200)

      json = JSON.parse(response.body)
      expect(json['hoojah_poll']['id']).to eq(poll.id)
    end

    it 'returns complete poll attributes' do
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'agree')
      HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'disagree')

      get "/hoojah/polls/#{topic.id}.json"

      json = JSON.parse(response.body)
      expect(json['hoojah_poll']['id']).to eq(poll.id)
      expect(json['hoojah_poll']['topic_id']).to eq(topic.id)
      expect(json['hoojah_poll']['enabled']).to eq(true)
      expect(json['hoojah_poll']['vote_counts']['agree']).to eq(1)
      expect(json['hoojah_poll']['vote_counts']['disagree']).to eq(1)
      expect(json['hoojah_poll']['vote_counts']['total']).to eq(2)
      expect(json['hoojah_poll']['created_at']).to be_present
    end

    it 'returns user_has_voted and user_vote when authenticated' do
      voter = Fabricate(:user)
      HoojahVote.create!(hoojah_poll: poll, user: voter, vote_type: 'neutral')
      sign_in(voter)

      get "/hoojah/polls/#{topic.id}.json"

      json = JSON.parse(response.body)
      expect(json['hoojah_poll']['user_has_voted']).to eq(true)
      expect(json['hoojah_poll']['user_vote']['vote_type']).to eq('neutral')
    end

    it 'returns 404 for non-existent poll' do
      get "/hoojah/polls/999999.json"
      expect(response.status).to eq(404)
    end
  end
end
