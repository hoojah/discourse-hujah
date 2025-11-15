# Hoojah - Discourse Poll Plugin

A Discourse plugin that adds agree/neutral/disagree polls to topics with reply categorization and filtering.

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)
![Discourse](https://img.shields.io/badge/discourse-2.7.0+-orange.svg)
![Tested](https://img.shields.io/badge/tested-v3.5.2-green.svg)

## Status

**Current Version:** 0.1.0 (Beta)
**Tested On:** Discourse v3.5.2 / Ember v5.12.0
**Status:** ✅ Stable - All critical bugs resolved

Recent improvements include fixes for vote serialization, UI feedback, trust level verification, and Ember v5 compatibility. See [Changelog](#changelog) for details.

## Features

- **3-Option Polling**: Add agree/neutral/disagree polls to any topic
- **Flexible Permissions**: Topic creators and moderators can enable Hoojah on topics
- **Vote Management**: Users can vote, change votes, or remove their vote
- **Reply Categorization**: Associate replies with agree/neutral/disagree stances
- **Filtered Views**: Tab-based filtering to view replies by stance
- **Real-time Updates**: Vote counts update in real-time via MessageBus
- **Responsive Design**: Mobile-friendly UI with touch-optimized controls
- **Customizable Settings**: Control who can vote and enable polls

## Screenshots

### Poll Widget
The poll widget displays at the top of enabled topics, showing vote buttons and statistics.

### Reply Stance Selector
When replying to a Hoojah-enabled topic, users can optionally select their stance.

### Filter Tabs
Filter replies by stance using the tab navigation below the poll widget.

## Installation

> **📖 For detailed installation instructions, see [INSTALLATION.md](./INSTALLATION.md)**

### Quick Install (Docker - Most Common)

Most production Discourse sites use Docker. Here's the quick version:

1. **SSH into your server**:
   ```bash
   ssh root@your-discourse-server.com
   cd /var/discourse
   ```

2. **Edit the configuration**:
   ```bash
   nano containers/app.yml
   ```

3. **Add the plugin** under `hooks:` → `after_code:` → `cmd:`:
   ```yaml
   - git clone https://github.com/hoojah/discourse-hujah.git
   ```

4. **Rebuild** (takes 5-10 minutes):
   ```bash
   ./launcher rebuild app
   ```

5. **Configure** at Admin → Settings → Plugins → hoojah

### Other Installation Methods

- **Managed Hosting**: Contact your hosting provider with the plugin repository URL
- **Development**: Clone into `discourse/plugins/` and restart Rails server
- **Troubleshooting**: See [INSTALLATION.md](./INSTALLATION.md) for detailed help

## Configuration

After installation, configure the plugin in **Admin → Settings → Plugins → Hoojah**:

### Available Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `hoojah_enabled` | `true` | Enable the Hoojah plugin globally |
| `hoojah_allow_topic_creators_enable` | `true` | Allow topic creators to enable Hoojah on their topics |
| `hoojah_min_trust_level_to_vote` | `0` | Minimum trust level required to vote (0-4) |
| `hoojah_show_vote_counts_to_voters_only` | `false` | Only show vote counts to users who have voted |

## Usage

### Enabling Hoojah on a Topic

1. Navigate to any topic
2. Click the **admin wrench** icon
3. Select **"Enable Hoojah Poll"**
4. The poll widget will appear at the top of the topic

### Voting

1. View a topic with Hoojah enabled
2. Click one of the three vote buttons: **Agree**, **Neutral**, or **Disagree**
3. Your vote is recorded and counts update in real-time
4. You can change your vote by clicking a different button
5. Remove your vote using the "Remove my vote" link

### Replying with a Stance

1. Click "Reply" on a Hoojah-enabled topic
2. In the composer, select your stance (optional): **Agree**, **Neutral**, **Disagree**, or **No stance**
3. Write your reply
4. Submit - your reply will be categorized by your selected stance

### Filtering Replies

1. Below the poll widget, use the tab filters:
   - **All Replies**: View all posts
   - **Agree**: View only replies marked as "agree"
   - **Neutral**: View only neutral replies
   - **Disagree**: View only disagreeing replies
2. Click any tab to filter the post stream

## Permissions

### Who Can Enable Hoojah?

- **Moderators and Admins**: Can always enable/disable Hoojah on any topic
- **Topic Creators**: Can enable Hoojah on their own topics (if `hoojah_allow_topic_creators_enable` is true)

### Who Can Vote?

- Any authenticated user meeting the minimum trust level requirement
- Trust level requirement is configurable (default: 0)

### Who Can Set Reply Stance?

- Any user who can reply to the topic
- Stance is optional when replying

## API Endpoints

### Polls

**Create/Enable Poll**
```
POST /hoojah/polls
Params: { topic_id: number }
```

**Get Poll Data**
```
GET /hoojah/polls/:topic_id
```

**Disable Poll**
```
DELETE /hoojah/polls/:topic_id
```

### Votes

**Cast Vote**
```
POST /hoojah/votes
Params: { poll_id: number, vote_type: 'agree'|'neutral'|'disagree' }
```

**Update Vote**
```
PUT /hoojah/votes/:poll_id
Params: { vote_type: 'agree'|'neutral'|'disagree' }
```

**Remove Vote**
```
DELETE /hoojah/votes/:poll_id
```

### Posts

**Get Filtered Posts**
```
GET /hoojah/posts/:topic_id?stance=agree|neutral|disagree|all
```

## Development

### Tested Versions

This plugin has been tested and verified working on:
- **Discourse**: v3.5.2 (minimum required: v2.7.0)
- **Ember**: v5.12.0
- **Ruby**: 3.2+
- **PostgreSQL**: 13+

### Running Tests

```bash
# In your Discourse directory
bundle exec rspec plugins/discourse-hujah/spec
```

### Code Structure

```
discourse-hujah/
├── plugin.rb                    # Main plugin file
├── app/
│   ├── controllers/hoojah/      # API controllers
│   └── serializers/             # JSON serializers
├── lib/hoojah/                  # Models and business logic
├── db/migrate/                  # Database migrations
├── assets/
│   ├── javascripts/discourse/   # Ember.js components
│   └── stylesheets/             # SCSS styles
├── config/
│   ├── locales/                 # Translations
│   └── settings.yml             # Plugin settings
└── spec/                        # Tests
```

### Database Schema

**hoojah_polls**
- Stores poll records for topics
- One poll per topic (unique constraint)

**hoojah_votes**
- Stores user votes
- One vote per user per poll (unique constraint)

**hoojah_post_stances**
- Links posts to stances
- One stance per post (unique constraint)

## Localization

The plugin supports internationalization. To add translations:

1. Create a new locale file in `config/locales/`
2. Copy the structure from `client.en.yml`
3. Translate the strings
4. Submit a pull request

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Troubleshooting

### Poll Not Showing

**Common Solutions:**
- Ensure `hoojah_enabled` is set to `true` in site settings
- Verify the topic has Hoojah enabled (check admin wrench menu)
- Check browser console for JavaScript errors
- Clear browser cache and hard reload (Ctrl+Shift+R)

**Recent Fix:** Property naming alignment between backend and frontend (v0.1.0)

### Can't Vote

**Common Solutions:**
- Confirm you're logged in
- Check your trust level meets the minimum requirement (default: TL0)
- Verify `hoojah_enabled` is true in site settings
- Check Rails logs for specific errors

**Recent Fix:** Trust level verification now uses correct API (v0.1.0)

### Votes Not Updating / 500 Errors

**Common Solutions:**
- Check MessageBus is working properly (look for WebSocket connections in Network tab)
- Verify no browser extensions are blocking WebSocket connections
- Look for errors in Rails logs (`/logs` in browser or server logs)
- Ensure plugin name is correctly set in controllers

**Recent Fixes:**
- Vote serialization with proper Guardian scope (v0.1.0)
- Poll data reloading after vote changes (v0.1.0)
- Controller plugin name verification (v0.1.0)

### Stance Not Saving

**Common Solutions:**
- Ensure you selected a stance before submitting the reply
- Check that the topic has Hoojah enabled
- Verify the post was created successfully
- Check Rails logs for database errors

### Advanced Troubleshooting

For detailed troubleshooting steps and fixes for Discourse v3.5.2+ / Ember v5.12+, see:
- [doc/ELECT_IO_FIXES.md](./doc/ELECT_IO_FIXES.md) - Comprehensive fix documentation
- Check Rails logs: `tail -f log/production.log` (or development.log)
- Check browser console for JavaScript errors (F12 → Console)
- Verify plugin is loaded: Admin → Plugins → look for "discourse-hujah"

## Support

- **Issues**: [GitHub Issues](https://github.com/hoojah/discourse-hujah/issues)
- **Discussions**: [Discourse Meta](https://meta.discourse.org/)

## License

MIT License - See LICENSE file for details

## Credits

Developed by the Hoojah Team for the Discourse community.

## Changelog

### Version 0.1.0 (2025-11-15)

**Initial Release - Hoojah Topic Poll Features**

Core Features:
- Three-option polling (agree/neutral/disagree)
- Reply stance categorization
- Filtered views by stance
- Real-time vote updates via MessageBus
- Mobile-responsive design
- Comprehensive test coverage

Recent Bug Fixes & Improvements:
- ✅ Fixed vote serialization issues by providing proper Guardian scope
- ✅ Fixed vote update UI feedback by reloading poll data after vote changes
- ✅ Fixed voting 500 errors by correcting trust level verification
- ✅ Fixed poll visibility by aligning property naming between backend and frontend
- ✅ Fixed critical bugs preventing plugin initialization
- ✅ Improved compatibility with Discourse v3.5.2 / Ember v5.12.0
- ✅ Fixed component template resolution for modern Ember
- ✅ Fixed MessageBus integration for real-time updates

**What's Next:**
- v0.2.0: 1-on-1 debate features (planned)
- v0.3.0: Analytics features (planned)
- v1.0.0: Public release (planned)

For detailed troubleshooting information, see [doc/ELECT_IO_FIXES.md](./doc/ELECT_IO_FIXES.md)
