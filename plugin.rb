# frozen_string_literal: true

# name: discourse-hujah
# about: A Discourse plugin that adds agree/neutral/disagree polls to topics with reply categorization
# version: 0.1.0
# authors: Hoojah Team
# url: https://github.com/hoojah/discourse-hujah
# required_version: 2.7.0

enabled_site_setting :hoojah_enabled

register_asset 'stylesheets/hoojah.scss'

after_initialize do
  module ::DiscourseHoojah
    PLUGIN_NAME ||= 'discourse-hujah'

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseHoojah
    end
  end

  # Load plugin files
  plugin_root = File.expand_path('..', __FILE__)
  [
    'lib/hoojah/engine.rb',
    'lib/hoojah/poll.rb',
    'lib/hoojah/vote.rb',
    'lib/hoojah/post_stance.rb',
    'app/controllers/hoojah/polls_controller.rb',
    'app/controllers/hoojah/votes_controller.rb',
    'app/controllers/hoojah/posts_controller.rb',
    'app/serializers/hoojah_poll_serializer.rb',
    'app/serializers/hoojah_vote_serializer.rb',
  ].each { |path| require File.join(plugin_root, path) }

  # Register routes
  DiscourseHoojah::Engine.routes.draw do
    post '/polls' => 'polls#create'
    delete '/polls/:topic_id' => 'polls#destroy'
    get '/polls/:topic_id' => 'polls#show'

    post '/votes' => 'votes#create'
    put '/votes/:poll_id' => 'votes#update'
    delete '/votes/:poll_id' => 'votes#destroy'

    get '/posts/:topic_id' => 'posts#index'
  end

  Discourse::Application.routes.append do
    mount ::DiscourseHoojah::Engine, at: '/hoojah'
  end

  # Extend Guardian for permissions
  require_dependency 'guardian'
  module GuardianExtensions
    def can_enable_hoojah?(topic)
      return false unless SiteSetting.hoojah_enabled
      return false unless topic

      is_staff? ||
        (topic.user_id == current_user&.id && SiteSetting.hoojah_allow_topic_creators_enable)
    end

    def can_vote_hoojah?(poll)
      return false unless SiteSetting.hoojah_enabled
      return false unless authenticated?
      return false unless poll
      return false unless poll.enabled

      # Check trust level - convert setting to integer
      min_trust_level = SiteSetting.hoojah_min_trust_level_to_vote.to_i
      current_user.trust_level >= min_trust_level
    end

    def can_set_post_stance?(post)
      return false unless SiteSetting.hoojah_enabled
      return false unless post

      is_my_own?(post)
    end
  end

  Guardian.class_eval do
    include GuardianExtensions
  end

  # Add hoojah data to TopicViewSerializer
  require_dependency 'topic_view_serializer'
  class ::TopicViewSerializer
    attributes :hoojah_poll

    def hoojah_poll
      @hoojah_poll ||= begin
        poll = HoojahPoll.find_by(topic_id: object.topic.id, enabled: true)
        if poll
          HoojahPollSerializer.new(poll, scope: scope, root: false).as_json
        end
      end
    end

    def include_hoojah_poll?
      hoojah_poll.present?
    end
  end

  # Add stance to PostSerializer
  require_dependency 'post_serializer'
  class ::PostSerializer
    attributes :hoojah_stance

    def hoojah_stance
      stance = HoojahPostStance.find_by(post_id: object.id)
      stance&.stance
    end

    def include_hoojah_stance?
      hoojah_stance.present?
    end
  end

  # MessageBus integration for real-time updates
  on(:hoojah_vote_changed) do |poll_id, topic_id|
    poll = HoojahPoll.find_by(id: poll_id)
    if poll
      MessageBus.publish(
        "/topic/#{topic_id}",
        {
          type: 'hoojah_vote_updated',
          hoojah_poll: HoojahPollSerializer.new(poll, scope: Guardian.new, root: false).as_json
        },
        user_ids: User.where("admin OR moderator OR id IN (SELECT user_id FROM topic_allowed_users WHERE topic_id = ?)", topic_id).pluck(:id)
      )
    end
  end

  on(:post_created) do |post, opts, user|
    # Check if post has hoojah_stance in opts
    if opts[:hoojah_stance].present? && post.topic
      poll = HoojahPoll.find_by(topic_id: post.topic_id, enabled: true)
      if poll && ['agree', 'neutral', 'disagree'].include?(opts[:hoojah_stance])
        HoojahPostStance.create!(
          post_id: post.id,
          hoojah_poll_id: poll.id,
          stance: opts[:hoojah_stance]
        )
      end
    end
  end
end
