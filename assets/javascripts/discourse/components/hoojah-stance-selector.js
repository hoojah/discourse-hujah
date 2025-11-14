import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { setComponentTemplate } from "@ember/component";
import { hbs } from "ember-cli-htmlbars";

const TEMPLATE = hbs`
<div class="hoojah-stance-selector">
  <label>{{i18n "hoojah.select_stance"}}</label>
  <div class="stance-buttons">
    {{#each this.stances as |stance|}}
      <button
        class="btn btn-small stance-btn {{stance.class}} {{if (this.isSelected stance.key) 'selected'}}"
        {{on "click" (fn this.selectStance stance.key)}}
      >
        {{#if stance.icon}}
          {{d-icon stance.icon}}
        {{/if}}
        {{stance.label}}
      </button>
    {{/each}}
  </div>
</div>
`;

export default setComponentTemplate(TEMPLATE, class HoojahStanceSelector extends Component {
  @tracked selectedStance = null;

  get stances() {
    return [
      { key: null, label: "No stance", icon: null },
      { key: "agree", label: "Agree", icon: "check", class: "agree" },
      { key: "neutral", label: "Neutral", icon: "minus", class: "neutral" },
      { key: "disagree", label: "Disagree", icon: "times", class: "disagree" },
    ];
  }

  @action
  selectStance(stance) {
    this.selectedStance = stance;
    if (this.args.onStanceChange) {
      this.args.onStanceChange(stance);
    }
  }

  @action
  isSelected(stanceKey) {
    return this.selectedStance === stanceKey;
  }
});
