# frozen_string_literal: true

module DiscourseHoojah
  class PollsController < ::ApplicationController
    requires_plugin 'discourse-hujah'

    before_action :ensure_logged_in, except: [:show]
    before_action :find_topic, only: [:create, :destroy, :show]

    def show
      poll = HoojahPoll.find_by(topic_id: params[:topic_id])

      if poll
        render_serialized(poll, HoojahPollSerializer, root: 'hoojah_poll')
      else
        render json: { hoojah_poll: nil }
      end
    end

    def create
      raise Discourse::InvalidAccess.new unless guardian.can_enable_hoojah?(@topic)

      # Check if poll already exists
      existing_poll = HoojahPoll.find_by(topic_id: @topic.id)
      if existing_poll
        existing_poll.update!(enabled: true)
        poll = existing_poll
      else
        poll = HoojahPoll.create!(
          topic_id: @topic.id,
          created_by_user_id: current_user.id,
          enabled: true
        )
      end

      MessageBus.publish("/hoojah/topic/#{@topic.id}", {
        type: 'hoojah_enabled',
        hoojah_poll: HoojahPollSerializer.new(poll, scope: guardian, root: false).as_json
      })

      render_serialized(poll, HoojahPollSerializer, root: 'hoojah_poll')
    end

    def destroy
      raise Discourse::InvalidAccess.new unless guardian.can_enable_hoojah?(@topic)

      poll = HoojahPoll.find_by(topic_id: params[:topic_id])
      if poll
        poll.update!(enabled: false)

        MessageBus.publish("/hoojah/topic/#{@topic.id}", {
          type: 'hoojah_disabled'
        })

        render json: success_json
      else
        render json: failed_json, status: 404
      end
    end

    private

    def find_topic
      @topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound unless @topic
    end
  end
end
