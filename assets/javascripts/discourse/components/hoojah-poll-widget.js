import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { setComponentTemplate } from "@ember/component";
import { hbs } from "ember-cli-htmlbars";
import templateOnly from "@ember/component/template-only";
import { getOwner } from "@ember/application";

const TEMPLATE = hbs`
<div class="hoojah-poll-widget">
  <div class="hoojah-poll-header">
    <div class="hoojah-header-content">
      <h3>{{i18n "hoojah.poll_title"}}</h3>
    </div>
    <div class="hoojah-header-actions">
      <div class="hoojah-share-dropdown {{if this.showShareMenu 'open'}}">
        <button
          class="btn btn-flat hoojah-share-btn"
          {{on "click" this.toggleShareMenu}}
          title="{{i18n 'hoojah.share'}}"
        >
          {{d-icon "share-alt"}}
          {{i18n "hoojah.share"}}
        </button>
        {{#if this.showShareMenu}}
          <div class="hoojah-share-menu">
            <button class="share-option" {{on "click" (fn this.shareVia "facebook")}}>
              {{d-icon "fab-facebook"}}
              {{i18n "hoojah.share_facebook"}}
            </button>
            <button class="share-option" {{on "click" (fn this.shareVia "twitter")}}>
              {{d-icon "fab-twitter"}}
              {{i18n "hoojah.share_twitter"}}
            </button>
            <button class="share-option" {{on "click" (fn this.shareVia "whatsapp")}}>
              {{d-icon "fab-whatsapp"}}
              {{i18n "hoojah.share_whatsapp"}}
            </button>
            <button class="share-option" {{on "click" (fn this.shareVia "telegram")}}>
              {{d-icon "fab-telegram"}}
              {{i18n "hoojah.share_telegram"}}
            </button>
            <button class="share-option" {{on "click" (fn this.shareVia "reddit")}}>
              {{d-icon "fab-reddit"}}
              {{i18n "hoojah.share_reddit"}}
            </button>
            <button class="share-option" {{on "click" (fn this.shareVia "email")}}>
              {{d-icon "envelope"}}
              {{i18n "hoojah.share_email"}}
            </button>
            <button class="share-option" {{on "click" this.copyLink}}>
              {{d-icon "link"}}
              {{i18n "hoojah.copy_link"}}
            </button>
          </div>
        {{/if}}
      </div>
    </div>
  </div>

  {{#if this.poll}}
    <div class="hoojah-poll-votes">
      <div class="hoojah-vote-buttons">
        <button
          class="btn hoojah-vote-btn agree {{if (eq this.userVote.vote_type 'agree') 'active voted'}}"
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
          class="btn hoojah-vote-btn neutral {{if (eq this.userVote.vote_type 'neutral') 'active voted'}}"
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
          class="btn hoojah-vote-btn disagree {{if (eq this.userVote.vote_type 'disagree') 'active voted'}}"
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
            <span class="agree-pct">{{this.agreePercentage}}% {{i18n "hoojah.agree"}}</span>
            <span class="neutral-pct">{{this.neutralPercentage}}% {{i18n "hoojah.neutral"}}</span>
            <span class="disagree-pct">{{this.disagreePercentage}}% {{i18n "hoojah.disagree"}}</span>
          </div>
        </div>
      {{/if}}

      <div class="hoojah-poll-footer">
        <div class="hoojah-stats-row">
          {{#if this.voteCounts}}
            <span class="total-votes">
              {{d-icon "poll-h"}}
              {{i18n "hoojah.total_votes" count=this.voteCounts.total}}
            </span>
          {{/if}}
          {{#if this.responseCount}}
            <span class="response-count">
              {{d-icon "comments"}}
              {{i18n "hoojah.response_count" count=this.responseCount}}
            </span>
          {{/if}}
        </div>

        <div class="hoojah-actions-row">
          {{#if this.userHasVoted}}
            <button
              class="btn btn-primary hoojah-add-response-btn"
              {{on "click" this.addResponse}}
            >
              {{d-icon "reply"}}
              {{i18n "hoojah.add_response"}}
            </button>
            <button
              class="btn-link hoojah-remove-vote-link"
              {{on "click" this.removeVote}}
              disabled={{this.isVoting}}
            >
              {{i18n "hoojah.remove_vote"}}
            </button>
          {{else}}
            <span class="vote-to-respond-hint">
              {{d-icon "info-circle"}}
              {{i18n "hoojah.vote_to_respond"}}
            </span>
          {{/if}}
        </div>
      </div>
    </div>
  {{/if}}
</div>
`;

export default setComponentTemplate(TEMPLATE, class HoojahPollWidget extends Component {
  @service currentUser;
  @service siteSettings;
  @service router;
  @service composer;
  @tracked isVoting = false;
  @tracked showShareMenu = false;

  get poll() {
    return this.args.poll;
  }

  get topic() {
    return this.args.topic;
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

  get responseCount() {
    return this.topic?.posts_count ? this.topic.posts_count - 1 : 0;
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

  get shareUrl() {
    return this.topic ? window.location.origin + this.topic.url : window.location.href;
  }

  get shareTitle() {
    return this.topic?.title || document.title;
  }

  @action
  toggleShareMenu() {
    this.showShareMenu = !this.showShareMenu;
  }

  @action
  shareVia(platform) {
    const url = encodeURIComponent(this.shareUrl);
    const title = encodeURIComponent(this.shareTitle);
    let shareUrl;

    switch (platform) {
      case "facebook":
        shareUrl = `https://www.facebook.com/sharer/sharer.php?u=${url}`;
        break;
      case "twitter":
        shareUrl = `https://twitter.com/intent/tweet?url=${url}&text=${title}`;
        break;
      case "whatsapp":
        shareUrl = `https://api.whatsapp.com/send?text=${title}%20${url}`;
        break;
      case "telegram":
        shareUrl = `https://t.me/share/url?url=${url}&text=${title}`;
        break;
      case "reddit":
        shareUrl = `https://reddit.com/submit?url=${url}&title=${title}`;
        break;
      case "email":
        shareUrl = `mailto:?subject=${title}&body=${url}`;
        break;
    }

    if (shareUrl) {
      window.open(shareUrl, "_blank", "width=600,height=400");
    }

    this.showShareMenu = false;
  }

  @action
  copyLink() {
    navigator.clipboard.writeText(this.shareUrl).then(() => {
      const appEvents = getOwner(this).lookup("service:app-events");
      if (appEvents) {
        appEvents.trigger("popup-menu:close");
      }
    });
    this.showShareMenu = false;
  }

  @action
  addResponse() {
    if (!this.topic) return;

    const composerService = getOwner(this).lookup("service:composer");
    if (composerService) {
      composerService.open({
        action: "reply",
        topic: this.topic,
        draftKey: this.topic.draft_key,
      });
    }
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
