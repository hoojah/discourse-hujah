# elect.io Specific Troubleshooting Guide - Fixed Issues

## Issues Resolved for Discourse v3.5.2 / Ember v5.12.0

This document tracks the issues encountered and fixed on the elect.io deployment.

---

## ✅ Issue 1: Infinite Loading Spinner

**Error**: `ReferenceError: Can't find variable: action`

**Cause**: Using `@action` decorator in `api.modifyClass()` which doesn't support decorators

**Fix**: Removed `@action` decorator from `setHoojahStance()` method in initializer

**Commit**: b91b887

---

## ✅ Issue 2: MessageBus Undefined

**Error**: `TypeError: can't access property "subscribe", e.messageBus is undefined`

**Cause**: `api.messageBus` doesn't exist in Discourse v3.5.2

**Fix**: Changed to `api.container.lookup("service:message-bus")`

**Commit**: f8ac911

---

## ✅ Issue 3: Component Template Resolving Deprecation

**Error**: Admin notice about component-template-resolving deprecation

**Cause**: Templates in `templates/components/` not colocated with component JS files

**Fix**: Moved `.hbs` files from `templates/components/` to `components/` directory

**Commit**: 7465e80

---

## ✅ Issue 4: Connector shouldRender Error

**Error**: `TypeError: this.shouldRender is not a function`

**Cause**: Calling `shouldRender()` manually in `setupComponent()` - it's a lifecycle hook, not a callable method

**Fix**: Removed manual call to `this.shouldRender()` and duplicated condition check instead

**File**: `assets/javascripts/discourse/connectors/composer-fields/hoojah-stance-field.js`

**Commit**: 8c37ebd

---

## ✅ Issue 5: VM BUG - Template Jumping Errors

**Error**: `VM BUG: Target must be set before attempting to jump`

**Cause**: Component templates still being resolved separately despite colocation

**Fix**: Converted components to use inline templates with `setComponentTemplate()` and `hbs` tagged templates

**Changes**:
- Removed separate `.hbs` files
- Embedded templates directly in component JS files using `setComponentTemplate`
- Properly associates templates with Glimmer component classes

**Commit**: 8c37ebd

---

## ✅ Issue 6: Version Number

**Change**: Updated from 1.0.0 to 0.1.0

**Reason**: Following project roadmap
- v0.1.0 = Hoojah topic poll features (current)
- v0.2.0 = 1-on-1 debate features (planned)
- v0.3.0 = Analytic features (planned)
- v1.0.0 = Public release (planned)

**Commit**: 8c37ebd

---

## ✅ Issue 7: Poll Not Appearing on Topic Page

**Error**: Poll widget not showing even though no JavaScript errors

**Cause**: Property naming mismatch between backend (snake_case `hoojah_poll`) and frontend checks (camelCase `hoojahEnabled` and `hoojahPoll`)

**Fix**:
- Changed all frontend references from `hoojahEnabled`/`hoojahPoll` to `hoojah_poll`
- Updated connector template condition from `@outletArgs.model.hoojahEnabled` to `@outletArgs.model.hoojah_poll`
- Updated MessageBus handlers to use `topic.set("hoojah_poll", ...)` instead of `hoojahPoll`
- Updated composer connector to check `composer.topic.hoojah_poll` instead of `hoojahEnabled`
- Removed unnecessary property copies in topic model init

**Files Changed**:
- `assets/javascripts/discourse/initializers/extend-for-hoojah.js`
- `assets/javascripts/discourse/templates/connectors/topic-above-post-stream/hoojah-poll-container.hbs`
- `assets/javascripts/discourse/connectors/topic-above-post-stream/hoojah-poll-container.js`
- `assets/javascripts/discourse/connectors/composer-fields/hoojah-stance-field.js`

**Commit**: 0425058

---

## ✅ Issue 8: Voting Returns 500 Error

**Error**: `XHR PUT https://.../hoojah/votes/2 [HTTP/2 500]`

**Cause**: The `can_vote_hoojah?` Guardian method was using `has_trust_level?()` which doesn't exist or was incompatible with the Discourse version

**Fix**:
- Changed from `current_user.has_trust_level?(setting)` to `current_user.trust_level >= min_trust_level`
- Added `.to_i` conversion for the site setting value
- Added check to ensure poll is enabled before allowing votes
- Used standard Discourse pattern for trust level verification

**Files Changed**:
- `plugin.rb` (lines 66-75)

**Commit**: 12f05c1

---

## Technical Details

### Component Structure (After Fixes)

```javascript
// Modern approach - inline template with setComponentTemplate
import { setComponentTemplate } from "@ember/component";
import { hbs } from "ember-cli-htmlbars";

const TEMPLATE = hbs`
  <div>...</div>
`;

export default setComponentTemplate(TEMPLATE, class MyComponent extends Component {
  // Component logic
});
```

### Why This Works

1. **No separate template lookup**: Template is directly associated with component class
2. **No deprecation warnings**: Ember knows the template is colocated via `setComponentTemplate`
3. **Compatible with Ember v5.12**: Uses modern Ember component patterns
4. **Future-proof**: Ready for eventual migration to `.gjs` format

---

## Testing Checklist for elect.io

After deploying these fixes:

- [ ] Page loads without infinite spinner
- [ ] No JavaScript errors in browser console
- [ ] Can enable Hoojah on a topic
- [ ] Poll widget displays correctly
- [ ] Can vote on poll (agree/neutral/disagree)
- [ ] Can reply to topic with stance selector
- [ ] Filter tabs appear below poll
- [ ] No deprecation warnings in Admin panel
- [ ] Real-time vote updates work

---

## Related Documentation

- [Handling Component-Template-Resolving Deprecation](https://meta.discourse.org/t/handling-the-component-template-resolving-deprecation/370019)
- [Discourse Plugin Development Guide](https://meta.discourse.org/t/beginners-guide-to-creating-discourse-plugins/30515)
- [Ember.js setComponentTemplate API](https://api.emberjs.com/ember/5.12/functions/@ember%2Fcomponent/setComponentTemplate)

---

*Last Updated: 2025-11-14*
*Plugin Version: 0.1.0*
*Discourse Version: v3.5.2*
*Ember Version: v5.12.0*
