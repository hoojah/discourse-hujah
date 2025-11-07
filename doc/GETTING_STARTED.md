# Getting Started with discourse-hujah

This guide will help you initialize and start developing this Discourse-related project.

---

## Current Status

⚠️ **This repository is currently empty.** No code, configuration, or structure has been set up yet.

---

## Prerequisites

Before starting development, ensure you have:

### For Discourse Plugin Development
- Ruby 3.0 or higher
- Rails 7.0 or higher
- PostgreSQL 13+
- Redis 6+
- Node.js 16+ and npm/yarn
- Git

### For Local Discourse Instance
- Docker and Docker Compose (recommended)
- 4GB+ RAM
- 10GB+ free disk space

---

## Option 1: Create a Discourse Plugin

### Step 1: Create Plugin Definition

Create `plugin.rb` in the root directory:

```ruby
# frozen_string_literal: true

# name: discourse-hujah
# about: A Discourse plugin
# version: 0.1.0
# authors: Your Name
# url: https://github.com/hoojah/discourse-hujah

enabled_site_setting :hujah_enabled

after_initialize do
  # Plugin initialization code goes here
end
```

### Step 2: Create Directory Structure

```bash
mkdir -p assets/javascripts
mkdir -p assets/stylesheets
mkdir -p config/locales
mkdir -p lib
mkdir -p spec
```

### Step 3: Add Configuration

Create `config/settings.yml`:

```yaml
plugins:
  hujah_enabled:
    default: true
    client: true
```

### Step 4: Add README

Create a README.md describing your plugin's purpose and features.

### Step 5: Test in Discourse

1. Clone Discourse: `git clone https://github.com/discourse/discourse.git`
2. Link your plugin: `cd discourse/plugins && ln -s /path/to/discourse-hujah .`
3. Run Discourse: Follow [installation guide](https://meta.discourse.org/t/beginners-guide-to-install-discourse-on-ubuntu-for-development/14727)

---

## Option 2: Create a Discourse Theme

### Step 1: Create Theme Metadata

Create `about.json`:

```json
{
  "name": "Hujah Theme",
  "about_url": "https://github.com/hoojah/discourse-hujah",
  "license_url": "https://github.com/hoojah/discourse-hujah/blob/main/LICENSE",
  "theme_version": "1.0.0",
  "minimum_discourse_version": "2.8.0",
  "assets": {},
  "color_schemes": {}
}
```

### Step 2: Create Style Files

```bash
mkdir -p common desktop mobile
touch common/common.scss
touch desktop/desktop.scss
touch mobile/mobile.scss
```

### Step 3: Install in Discourse

1. Go to Admin → Customize → Themes
2. Click "Install" → "From a git repository"
3. Enter your repository URL

---

## Option 3: Set Up Full Discourse Development Environment

### Using Docker (Recommended)

1. Clone Discourse:
   ```bash
   git clone https://github.com/discourse/discourse.git
   cd discourse
   ```

2. Start development environment:
   ```bash
   ./bin/docker/boot_dev
   ./bin/docker/bundle exec rake db:create db:migrate
   ```

3. Run server:
   ```bash
   ./bin/docker/rails s
   ```

### Local Installation

Follow the official guide:
https://meta.discourse.org/t/beginners-guide-to-install-discourse-on-ubuntu-for-development/14727

---

## Development Workflow

### 1. Set Up Version Control

```bash
# Already done - repository is initialized
git status
```

### 2. Create Feature Branches

```bash
git checkout -b feature/your-feature-name
```

### 3. Make Changes

Edit files, add functionality, write tests.

### 4. Test Your Changes

For plugins:
```bash
bundle exec rspec spec/
```

For themes:
- Test in a local Discourse instance
- Check responsive design on different devices

### 5. Commit and Push

```bash
git add .
git commit -m "Add feature: description"
git push -u origin feature/your-feature-name
```

---

## Essential Resources

### Documentation
- [Discourse Developer Docs](https://docs.discourse.org/)
- [Plugin Development Guide](https://meta.discourse.org/t/beginners-guide-to-creating-discourse-plugins/30515)
- [Theme Development Guide](https://meta.discourse.org/t/developer-s-guide-to-discourse-themes/93648)
- [API Documentation](https://docs.discourse.org/)

### Community
- [Discourse Meta](https://meta.discourse.org/) - Official community forum
- [GitHub Discussions](https://github.com/discourse/discourse/discussions)

### Example Plugins
- [discourse-voting](https://github.com/discourse/discourse-voting)
- [discourse-solved](https://github.com/discourse/discourse-solved)
- [discourse-calendar](https://github.com/discourse/discourse-calendar)

### Example Themes
- [Graceful](https://github.com/discourse/graceful)
- [Brand Header Theme](https://github.com/discourse/discourse-brand-header)

---

## Troubleshooting

### Common Issues

**Ruby version mismatch:**
```bash
rbenv install 3.2.0
rbenv local 3.2.0
```

**Database connection errors:**
- Ensure PostgreSQL is running
- Check `config/database.yml`

**Redis connection errors:**
- Ensure Redis is running: `redis-cli ping`

**Asset compilation errors:**
- Clear cache: `rake assets:clean`
- Reinstall dependencies: `bundle install && yarn install`

---

## Next Steps

1. ✅ Review the [REPOSITORY_ANALYSIS.md](./REPOSITORY_ANALYSIS.md)
2. 📝 Decide on project type (plugin, theme, or full instance)
3. 🏗️ Initialize project structure
4. 📚 Write README.md with project goals
5. 💻 Start coding!

---

For detailed analysis and recommendations, see [REPOSITORY_ANALYSIS.md](./REPOSITORY_ANALYSIS.md).
