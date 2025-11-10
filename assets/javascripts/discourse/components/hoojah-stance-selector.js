import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";

export default class HoojahStanceSelector extends Component {
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
}
