import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class HoojahPollWidget extends Component {
  @service currentUser;
  @service siteSettings;
  @tracked isVoting = false;

  get poll() {
    return this.args.poll;
  }

  get voteCounts() {
    return this.poll?.vote_counts || { agree: 0, neutral: 0, disagree: 0, total: 0 };
  }

  get userVote() {
    return this.poll?.user_vote;
  }

  get userHasVoted() {
    return this.poll?.user_has_voted || false;
  }

  get canVote() {
    if (!this.currentUser) return false;
    if (!this.siteSettings.hoojah_enabled) return false;

    const minTrustLevel = this.siteSettings.hoojah_min_trust_level_to_vote;
    return this.currentUser.trust_level >= minTrustLevel;
  }

  get agreePercentage() {
    if (this.voteCounts.total === 0) return 0;
    return Math.round((this.voteCounts.agree / this.voteCounts.total) * 100);
  }

  get neutralPercentage() {
    if (this.voteCounts.total === 0) return 0;
    return Math.round((this.voteCounts.neutral / this.voteCounts.total) * 100);
  }

  get disagreePercentage() {
    if (this.voteCounts.total === 0) return 0;
    return Math.round((this.voteCounts.disagree / this.voteCounts.total) * 100);
  }

  @action
  vote(voteType) {
    if (!this.canVote || this.isVoting) return;

    this.isVoting = true;

    const pollId = this.poll.id;
    const isUpdate = this.userHasVoted;
    const endpoint = isUpdate ? `/hoojah/votes/${pollId}` : "/hoojah/votes";
    const method = isUpdate ? "PUT" : "POST";

    ajax(endpoint, {
      type: method,
      data: { poll_id: pollId, vote_type: voteType },
    })
      .then((result) => {
        this.args.onPollUpdate(result.hoojah_poll);
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.isVoting = false;
      });
  }

  @action
  removeVote() {
    if (!this.userHasVoted || this.isVoting) return;

    this.isVoting = true;

    ajax(`/hoojah/votes/${this.poll.id}`, {
      type: "DELETE",
    })
      .then((result) => {
        this.args.onPollUpdate(result.hoojah_poll);
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.isVoting = false;
      });
  }
}
