# frozen_string_literal: true

class HoojahVoteSerializer < ApplicationSerializer
  attributes :id, :vote_type, :created_at, :updated_at

  def vote_type
    object.vote_type
  end
end
