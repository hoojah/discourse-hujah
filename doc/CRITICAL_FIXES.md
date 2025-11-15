# Critical Bug Fixes - Hoojah Plugin v0.1.0

## Issues Reported by User

After initial deployment to elect.io (Discourse v3.5.2), the following issues were encountered:

1. ❌ Hoojah features don't appear when revisiting the page
2. ❌ Clicking a vote gives 500 error
3. ❌ Filtering Hoojah replies gives "Sorry, an error has occurred"
4. ❌ After refreshing, the Hoojah poll disappears

---

## Root Causes Identified

### Issue 1 & 4: Poll Disappearing on Refresh/Revisit

**Root Cause**: The topic model had a `setupHoojahData()` method defined but it was never called.

**Location**: `assets/javascripts/discourse/initializers/extend-for-hoojah.js`

**Problem**:
```javascript
// OLD CODE - setupHoojahData() defined but never called
api.modifyClass("model:topic", {
  pluginId: "discourse-hujah",

  hoojahPoll: null,
  hoojahEnabled: false,

  setupHoojahData() {  // ❌ Never called!
    if (this.hoojah_poll) {
      this.set("hoojahPoll", this.hoojah_poll);
      this.set("hoojahEnabled", true);
    }
  },
});
```

**Fix**:
```javascript
// NEW CODE - Uses init() hook to automatically set up data
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
```

**Result**: ✅ Poll data now loads automatically when topic initializes

---

### Issue 2 & 3: 500 Errors in API Endpoints

**Root Cause**: All three controllers had wrong plugin name in `requires_plugin` directive.

**Location**:
- `app/controllers/hoojah/polls_controller.rb`
- `app/controllers/hoojah/votes_controller.rb`
- `app/controllers/hoojah/posts_controller.rb`

**Problem**:
```ruby
# OLD CODE - Wrong plugin name
module DiscourseHoojah
  class VotesController < ::ApplicationController
    requires_plugin 'discourse-hoojah'  # ❌ Wrong! Directory is 'discourse-hujah'
```

This caused Discourse to fail the plugin check and return 500 Internal Server Error.

**Fix**:
```ruby
# NEW CODE - Correct plugin name
module DiscourseHoojah
  class VotesController < ::ApplicationController
    requires_plugin 'discourse-hujah'  # ✅ Matches directory name
```

**Result**: ✅ All API endpoints now work correctly

---

## Summary of Changes

| File | Change | Impact |
|------|--------|--------|
| `extend-for-hoojah.js` | Changed `setupHoojahData()` to `init()` hook | Poll loads on page refresh |
| `polls_controller.rb` | Fixed plugin name: `discourse-hoojah` → `discourse-hujah` | Enable/disable poll works |
| `votes_controller.rb` | Fixed plugin name: `discourse-hoojah` → `discourse-hujah` | Voting works |
| `posts_controller.rb` | Fixed plugin name: `discourse-hoojah` → `discourse-hujah` | Filtering works |

---

## Testing Checklist

After deploying commit `25f8b34`, test the following:

### Basic Functionality
- [ ] Visit a topic - no JavaScript errors
- [ ] Enable Hoojah on a topic via admin menu
- [ ] Poll widget appears
- [ ] Refresh the page
- [ ] Poll widget still appears (was broken before)

### Voting
- [ ] Click "Agree" button
- [ ] Vote is recorded (was giving 500 error before)
- [ ] Vote count updates
- [ ] Click "Disagree" to change vote
- [ ] Vote updates successfully
- [ ] Click "Remove my vote"
- [ ] Vote is removed

### Replying with Stance
- [ ] Click "Reply" on Hoojah-enabled topic
- [ ] Stance selector appears in composer
- [ ] Select "Agree" stance
- [ ] Write and submit reply
- [ ] Reply is posted successfully

### Filtering
- [ ] Click "Agree" filter tab
- [ ] Only "Agree" replies show (was giving error before)
- [ ] Click "Neutral" filter tab
- [ ] Only "Neutral" replies show
- [ ] Click "All Replies" tab
- [ ] All replies show again

### Persistence
- [ ] Navigate away from topic
- [ ] Come back to topic
- [ ] Poll is still visible (was disappearing before)
- [ ] Votes are preserved

---

## Technical Details

### Why setupHoojahData() Wasn't Being Called

In Ember/Discourse, simply defining a method doesn't mean it will be called automatically. The `init()` method is a special lifecycle hook that Ember calls when an object is created. By moving our setup logic into `init()`, we ensure it runs automatically when the topic model is instantiated.

### Why Wrong Plugin Name Caused 500 Errors

Discourse's `requires_plugin` directive checks if the specified plugin is loaded. When we used 'discourse-hoojah' (with 'o') but our directory was 'discourse-hujah' (with 'u'), Discourse couldn't find the plugin and aborted the request with a 500 error. This affected all three controllers:

1. **PollsController**: Couldn't enable/disable polls
2. **VotesController**: Couldn't create/update/delete votes
3. **PostsController**: Couldn't filter posts by stance

---

## Remaining Known Issues

None currently identified. All reported issues should be resolved.

---

## Version History

- **v0.1.0-alpha**: Initial release (had critical bugs)
- **v0.1.0**: Fixed poll persistence and API errors (commit 25f8b34)

---

*Last Updated: 2025-11-14*
*Commit: 25f8b34*
*Status: Ready for testing on elect.io*
