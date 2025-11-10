# frozen_string_literal: true

require 'rails_helper'

describe HoojahVote do
  let(:user) { Fabricate(:user) }
  let(:topic) { Fabricate(:topic) }
  let(:poll) { Fabricate(:hoojah_poll, topic: topic, created_by_user: user) }

  describe 'validations' do
    it 'requires a hoojah_poll_id' do
      vote = HoojahVote.new(user_id: user.id, vote_type: 'agree')
      expect(vote.valid?).to eq(false)
      expect(vote.errors[:hoojah_poll_id]).to be_present
    end

    it 'requires a user_id' do
      vote = HoojahVote.new(hoojah_poll_id: poll.id, vote_type: 'agree')
      expect(vote.valid?).to eq(false)
      expect(vote.errors[:user_id]).to be_present
    end

    it 'requires a valid vote_type' do
      vote = HoojahVote.new(hoojah_poll_id: poll.id, user_id: user.id, vote_type: 'invalid')
      expect(vote.valid?).to eq(false)
      expect(vote.errors[:vote_type]).to be_present
    end

    it 'accepts valid vote types' do
      %w[agree neutral disagree].each do |type|
        vote = HoojahVote.new(hoojah_poll_id: poll.id, user: Fabricate(:user), vote_type: type)
        expect(vote.valid?).to eq(true)
      end
    end

    it 'ensures one vote per user per poll' do
      HoojahVote.create!(hoojah_poll: poll, user: user, vote_type: 'agree')
      duplicate = HoojahVote.new(hoojah_poll: poll, user: user, vote_type: 'disagree')
      expect(duplicate.valid?).to eq(false)
    end
  end
end
