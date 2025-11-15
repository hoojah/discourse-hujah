import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { setComponentTemplate } from "@ember/component";
import { hbs } from "ember-cli-htmlbars";
import templateOnly from "@ember/component/template-only";

const TEMPLATE = hbs`
<div class="hoojah-poll-widget">
  <div class="hoojah-poll-header">
    <h3>{{i18n "hoojah.poll_title"}}</h3>
  </div>

  {{#if this.poll}}
    <div class="hoojah-poll-votes">
      <div class="hoojah-vote-buttons">
        <button
          class="btn hoojah-vote-btn agree {{if (eq this.userVote.vote_type 'agree') 'active'}}"
          {{on "click" (fn this.vote "agree")}}
          disabled={{this.isVoting}}
        >
          {{d-icon "check"}}
          {{i18n "hoojah.agree"}}
          {{#if this.voteCounts}}
            <span class="vote-count">{{this.voteCounts.agree}}</span>
          {{/if}}
        </button>

        <button
          class="btn hoojah-vote-btn neutral {{if (eq this.userVote.vote_type 'neutral') 'active'}}"
          {{on "click" (fn this.vote "neutral")}}
          disabled={{this.isVoting}}
        >
          {{d-icon "minus"}}
          {{i18n "hoojah.neutral"}}
          {{#if this.voteCounts}}
            <span class="vote-count">{{this.voteCounts.neutral}}</span>
          {{/if}}
        </button>

        <button
          class="btn hoojah-vote-btn disagree {{if (eq this.userVote.vote_type 'disagree') 'active'}}"
          {{on "click" (fn this.vote "disagree")}}
          disabled={{this.isVoting}}
        >
          {{d-icon "times"}}
          {{i18n "hoojah.disagree"}}
          {{#if this.voteCounts}}
            <span class="vote-count">{{this.voteCounts.disagree}}</span>
          {{/if}}
        </button>
      </div>

      {{#if this.voteCounts}}
        <div class="hoojah-vote-stats">
          <div class="vote-bar-container">
            <div class="vote-bar agree" style="width: {{this.agreePercentage}}%"></div>
            <div class="vote-bar neutral" style="width: {{this.neutralPercentage}}%"></div>
            <div class="vote-bar disagree" style="width: {{this.disagreePercentage}}%"></div>
          </div>
          <div class="vote-percentages">
            <span class="agree-pct">{{this.agreePercentage}}% Agree</span>
            <span class="neutral-pct">{{this.neutralPercentage}}% Neutral</span>
            <span class="disagree-pct">{{this.disagreePercentage}}% Disagree</span>
          </div>
          <div class="total-votes">
            {{i18n "hoojah.total_votes" count=this.voteCounts.total}}
          </div>
        </div>
      {{/if}}

      {{#if this.userHasVoted}}
        <div class="hoojah-remove-vote">
          <button
            class="btn-link"
            {{on "click" this.removeVote}}
            disabled={{this.isVoting}}
          >
            {{i18n "hoojah.remove_vote"}}
          </button>
        </div>
      {{/if}}
    </div>
  {{/if}}
</div>
`;

export default setComponentTemplate(TEMPLATE, class HoojahPollWidget extends Component {
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
});
