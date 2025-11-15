# frozen_string_literal: true

module DiscourseHoojah
  class PostsController < ::ApplicationController
    requires_plugin 'discourse-hujah'

    before_action :find_topic

    def index
      poll = HoojahPoll.find_by(topic_id: @topic.id, enabled: true)
      raise Discourse::NotFound unless poll

      stance = params[:stance] || 'all'

      posts = if stance == 'all'
        @topic.posts.order(:created_at)
      elsif ['agree', 'neutral', 'disagree', 'none'].include?(stance)
        poll.posts_by_stance(stance)
      else
        raise Discourse::InvalidParameters.new(:stance)
      end

      # Apply pagination
      page = params[:page].to_i
      page = 1 if page < 1
      per_page = 20

      posts = posts.includes(:user).offset((page - 1) * per_page).limit(per_page)

      render_serialized(posts, PostSerializer, root: 'posts')
    end

    private

    def find_topic
      @topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound unless @topic
    end
  end
end
