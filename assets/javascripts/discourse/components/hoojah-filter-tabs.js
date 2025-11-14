import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { setComponentTemplate } from "@ember/component";
import { hbs } from "ember-cli-htmlbars";

const TEMPLATE = hbs`
<div class="hoojah-filter-tabs">
  <ul class="nav nav-pills">
    {{#each this.filters as |filter|}}
      <li class="nav-item">
        <a
          href="#"
          class="nav-link {{if (this.isActive filter.key) 'active'}}"
          {{on "click" (fn this.selectFilter filter.key)}}
        >
          {{#if filter.icon}}
            {{d-icon filter.icon}}
          {{/if}}
          {{filter.label}}
        </a>
      </li>
    {{/each}}
  </ul>
</div>
`;

export default setComponentTemplate(TEMPLATE, class HoojahFilterTabs extends Component {
  @tracked currentFilter = "all";

  get filters() {
    const counts = this.args.poll?.vote_counts || { agree: 0, neutral: 0, disagree: 0 };

    return [
      { key: "all", label: "All Replies", icon: "list" },
      { key: "agree", label: `Agree (${counts.agree})`, icon: "check", count: counts.agree },
      { key: "neutral", label: `Neutral (${counts.neutral})`, icon: "minus", count: counts.neutral },
      { key: "disagree", label: `Disagree (${counts.disagree})`, icon: "times", count: counts.disagree },
    ];
  }

  @action
  selectFilter(filterKey) {
    this.currentFilter = filterKey;
    if (this.args.onFilterChange) {
      this.args.onFilterChange(filterKey);
    }
  }

  @action
  isActive(filterKey) {
    return this.currentFilter === filterKey;
  }
});
