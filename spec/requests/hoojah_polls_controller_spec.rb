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
  end
end
