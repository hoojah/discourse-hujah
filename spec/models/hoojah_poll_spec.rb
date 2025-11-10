# frozen_string_literal: true

require 'rails_helper'

describe HoojahPoll do
  let(:user) { Fabricate(:user) }
  let(:topic) { Fabricate(:topic, user: user) }

  describe 'validations' do
    it 'requires a topic_id' do
      poll = HoojahPoll.new(created_by_user_id: user.id)
      expect(poll.valid?).to eq(false)
      expect(poll.errors[:topic_id]).to be_present
    end

    it 'requires a created_by_user_id' do
      poll = HoojahPoll.new(topic_id: topic.id)
      expect(poll.valid?).to eq(false)
      expect(poll.errors[:created_by_user_id]).to be_present
    end

    it 'ensures topic_id is unique' do
      HoojahPoll.create!(topic_id: topic.id, created_by_user_id: user.id)
      duplicate = HoojahPoll.new(topic_id: topic.id, created_by_user_id: user.id)
      expect(duplicate.valid?).to eq(false)
    end
  end

  describe '#vote_counts' do
    let(:poll) { Fabricate(:hoojah_poll, topic: topic, created_by_user: user) }

    it 'returns correct vote counts' do
      3.times { HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'agree') }
      2.times { HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'neutral') }
      1.times { HoojahVote.create!(hoojah_poll: poll, user: Fabricate(:user), vote_type: 'disagree') }

      counts = poll.vote_counts
      expect(counts[:agree]).to eq(3)
      expect(counts[:neutral]).to eq(2)
      expect(counts[:disagree]).to eq(1)
      expect(counts[:total]).to eq(6)
    end
  end

  describe '#user_has_voted?' do
    let(:poll) { Fabricate(:hoojah_poll, topic: topic, created_by_user: user) }
    let(:voter) { Fabricate(:user) }

    it 'returns false when user has not voted' do
      expect(poll.user_has_voted?(voter)).to eq(false)
    end

    it 'returns true when user has voted' do
      HoojahVote.create!(hoojah_poll: poll, user: voter, vote_type: 'agree')
      expect(poll.user_has_voted?(voter)).to eq(true)
    end
  end
end
