import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

function initializeHoojah(api) {
  const currentUser = api.getCurrentUser();

  // Add hoojah poll data to topic model
  api.modifyClass("model:topic", {
    pluginId: "discourse-hujah",

    init() {
      this._super(...arguments);
      // Set up hoojah data when topic is initialized
      if (this.hoojah_poll) {
        this.set("hoojahPoll", this.hoojah_poll);
        this.set("hoojahEnabled", true);
      }
    },
  });

  // Add stance to composer model
  api.modifyClass("model:composer", {
    pluginId: "discourse-hujah",

    hoojahStance: null,

    setHoojahStance(stance) {
      this.set("hoojahStance", stance);
    },
  });

  // Subscribe to MessageBus for real-time updates
  api.onPageChange((url, title) => {
    if (url.match(/^\/t\//)) {
      const topicId = url.split("/")[2];
      if (topicId) {
        const messageBus = api.container.lookup("service:message-bus");
        if (messageBus) {
          messageBus.subscribe(`/topic/${topicId}`, (data) => {
            if (data.type === "hoojah_vote_updated" && data.hoojah_poll) {
              const topic = api.container.lookup("controller:topic").model;
              if (topic && topic.id == topicId) {
                topic.set("hoojahPoll", data.hoojah_poll);
              }
            } else if (data.type === "hoojah_enabled" && data.hoojah_poll) {
              const topic = api.container.lookup("controller:topic").model;
              if (topic && topic.id == topicId) {
                topic.set("hoojahPoll", data.hoojah_poll);
                topic.set("hoojahEnabled", true);
              }
            } else if (data.type === "hoojah_disabled") {
              const topic = api.container.lookup("controller:topic").model;
              if (topic && topic.id == topicId) {
                topic.set("hoojahEnabled", false);
              }
            } else if (data.type === "hoojah_post_stance_updated") {
              // Refresh post stream to show updated stance
              const topic = api.container.lookup("controller:topic");
              if (topic && topic.model && topic.model.id == topicId) {
                topic.get("model.postStream").triggerChangedPost(data.post_id);
              }
            }
          });
        }
      }
    }
  });

  // Add admin menu option to enable/disable hoojah
  api.addTopicAdminMenuButton((topic) => {
    if (!currentUser) return;

    const canEnable =
      currentUser.staff ||
      (currentUser.id === topic.user_id &&
        api.container.lookup("site-settings:main").hoojah_allow_topic_creators_enable);

    if (!canEnable) return;

    return {
      className: "topic-admin-hoojah",
      label: topic.hoojahEnabled
        ? "hoojah.disable_hoojah"
        : "hoojah.enable_hoojah",
      icon: topic.hoojahEnabled ? "times" : "poll",
      action: () => {
        if (topic.hoojahEnabled) {
          ajax(`/hoojah/polls/${topic.id}`, {
            type: "DELETE",
          })
            .then(() => {
              topic.set("hoojahEnabled", false);
              topic.set("hoojahPoll", null);
            })
            .catch(popupAjaxError);
        } else {
          ajax("/hoojah/polls", {
            type: "POST",
            data: { topic_id: topic.id },
          })
            .then((result) => {
              topic.set("hoojahPoll", result.hoojah_poll);
              topic.set("hoojahEnabled", true);
            })
            .catch(popupAjaxError);
        }
      },
    };
  });

  // Modify post creation to include stance
  api.modifyClass("model:post", {
    pluginId: "discourse-hujah",

    createProperties() {
      const props = this._super(...arguments);
      const composer = this.composer;

      if (composer && composer.hoojahStance) {
        props.hoojah_stance = composer.hoojahStance;
      }

      return props;
    },
  });
}

export default {
  name: "extend-for-hoojah",

  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    if (!siteSettings.hoojah_enabled) {
      return;
    }

    withPluginApi("0.11.0", initializeHoojah);
  },
};
