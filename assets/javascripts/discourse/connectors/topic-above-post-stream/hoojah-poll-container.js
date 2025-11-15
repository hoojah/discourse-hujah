import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
  setupComponent(args, component) {
    component.setProperties({
      currentStanceFilter: "all",
    });
  },

  actions: {
    updateHoojahPoll(poll) {
      const topic = this.args.model;
      if (topic) {
        topic.set("hoojah_poll", poll);
      }
    },

    filterPostsByStance(stance) {
      this.set("currentStanceFilter", stance);

      const topic = this.args.model;
      if (!topic || stance === "all") {
        // Reset to show all posts
        if (topic && topic.postStream) {
          topic.postStream.cancelFilter();
          topic.postStream.refresh();
        }
        return;
      }

      // Filter posts by stance
      ajax(`/hoojah/posts/${topic.id}`, {
        data: { stance: stance },
      })
        .then((result) => {
          if (topic.postStream && result.posts) {
            const postIds = result.posts.map((p) => p.id);
            topic.postStream.filterPostIds(postIds);
          }
        })
        .catch(popupAjaxError);
    },
  },
};
