# Hoojah Plugin - Installation Guide for Discourse Admins

This guide provides step-by-step instructions for installing the Hoojah plugin on an existing Discourse-powered website.

---

## Prerequisites

- Admin access to your Discourse server
- SSH access to your server (for Docker installations)
- Basic familiarity with command line

---

## Installation Method 1: Docker (Recommended for Production)

This is the **most common** installation method for production Discourse sites.

### Step 1: Connect to Your Server

```bash
ssh root@your-discourse-server.com
```

### Step 2: Navigate to Discourse Directory

```bash
cd /var/discourse
```

### Step 3: Edit the Container Configuration

```bash
nano containers/app.yml
```

### Step 4: Add Plugin to Configuration

Find the `hooks:` section and add the Hoojah plugin under `after_code:`. It should look like this:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/docker_manager.git
          - git clone https://github.com/hoojah/discourse-hujah.git
```

**Note**: Replace `https://github.com/hoojah/discourse-hujah.git` with the actual repository URL.

If you're using a private repository, you may need to set up SSH keys or use a personal access token:

```yaml
          - git clone https://YOUR_TOKEN@github.com/hoojah/discourse-hujah.git
```

### Step 5: Save and Exit

- Press `Ctrl + X`
- Press `Y` to confirm
- Press `Enter` to save

### Step 6: Rebuild the Container

This will install the plugin and restart Discourse:

```bash
./launcher rebuild app
```

**Important**: This process typically takes 5-10 minutes and will cause brief downtime (usually 2-3 minutes during the restart phase).

### Step 7: Verify Installation

1. Visit your Discourse site
2. Log in as admin
3. Go to **Admin** → **Plugins**
4. Look for "discourse-hoojah" in the plugin list
5. You should see it with version 1.0.0

---

## Installation Method 2: Development Environment

For local development or testing on a non-Docker Discourse instance:

### Step 1: Navigate to Plugins Directory

```bash
cd /path/to/discourse/plugins
```

### Step 2: Clone the Repository

```bash
git clone https://github.com/hoojah/discourse-hujah.git
```

### Step 3: Install Dependencies

```bash
cd discourse-hujah
bundle install
```

### Step 4: Run Database Migrations

```bash
cd ../..  # Back to discourse root
bundle exec rake db:migrate
```

### Step 5: Restart Discourse

```bash
# Stop the server (Ctrl+C if running)
bundle exec rails server
```

Or if using Unicorn:

```bash
bundle exec unicorn -c config/unicorn.conf.rb
```

---

## Installation Method 3: Managed Hosting

If you're using a managed Discourse host (like Communiteq, DiscourseHosting, etc.):

### Step 1: Contact Your Host

Most managed hosts have specific procedures for installing plugins. Contact their support with:

- Plugin name: "Hoojah"
- Repository URL: `https://github.com/hoojah/discourse-hujah.git`
- Branch: `main` (or specify another branch)

### Step 2: Wait for Installation

Your hosting provider will install the plugin and notify you when complete.

---

## Post-Installation Configuration

### Step 1: Access Plugin Settings

1. Go to **Admin Panel** (click on your avatar → Admin)
2. Navigate to **Settings** → **Plugins**
3. Find **hoojah** in the settings list

### Step 2: Configure Settings

Adjust these settings according to your needs:

| Setting | Description | Recommended Value |
|---------|-------------|-------------------|
| **hoojah enabled** | Global enable/disable | ✅ Enabled |
| **hoojah allow topic creators enable** | Let topic creators enable polls | ✅ Enabled (for community engagement) |
| **hoojah min trust level to vote** | Minimum trust level to vote | `0` (allow all users) or `1` (basic users) |
| **hoojah show vote counts to voters only** | Hide counts from non-voters | ❌ Disabled (for transparency) |

### Step 3: Test the Plugin

1. Create a test topic or open an existing one
2. Click the **wrench icon** (admin menu)
3. Select **"Enable Hoojah Poll"**
4. Verify the poll widget appears
5. Try voting with different user accounts
6. Test the stance selector when replying
7. Test filtering posts by stance

---

## Updating the Plugin

### For Docker Installations

```bash
cd /var/discourse
./launcher rebuild app
```

This will automatically pull the latest version of the plugin.

### For Development Installations

```bash
cd /path/to/discourse/plugins/discourse-hujah
git pull origin main
cd ../..
bundle exec rake db:migrate
# Restart your server
```

---

## Uninstalling the Plugin

### For Docker Installations

1. Edit `containers/app.yml`:
   ```bash
   cd /var/discourse
   nano containers/app.yml
   ```

2. Remove the Hoojah line:
   ```yaml
   - git clone https://github.com/hoojah/discourse-hujah.git
   ```

3. Rebuild:
   ```bash
   ./launcher rebuild app
   ```

### For Development Installations

```bash
cd /path/to/discourse/plugins
rm -rf discourse-hujah
# Restart your server
```

**Note**: Uninstalling won't delete the database tables. To fully remove data:

```bash
# In Discourse root directory
rails console
```

Then run:
```ruby
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS hoojah_polls CASCADE")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS hoojah_votes CASCADE")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS hoojah_post_stances CASCADE")
```

---

## Troubleshooting

### Plugin Not Appearing in Admin

**Problem**: Plugin doesn't show in Admin → Plugins

**Solutions**:
1. Check that rebuild completed successfully:
   ```bash
   cd /var/discourse
   ./launcher logs app
   ```
   Look for any errors related to "hoojah"

2. Verify the plugin directory exists:
   ```bash
   ./launcher enter app
   ls -la /var/www/discourse/plugins/
   exit
   ```
   You should see `discourse-hujah` listed

3. Check plugin.rb syntax:
   ```bash
   ./launcher enter app
   cd plugins/discourse-hujah
   ruby -c plugin.rb
   exit
   ```

### Database Migration Errors

**Problem**: Errors about database tables or migrations

**Solution**:
```bash
cd /var/discourse
./launcher enter app
cd /var/www/discourse
su discourse -c 'bundle exec rake db:migrate'
exit
```

### "Enable Hoojah" Not Showing

**Problem**: Admin menu doesn't show the enable option

**Solutions**:
1. Verify `hoojah_enabled` is set to true in settings
2. Clear browser cache
3. Check JavaScript console for errors (F12 → Console tab)
4. Ensure you have proper permissions (admin or topic creator)

### Votes Not Working

**Problem**: Can't cast votes or votes not saving

**Solutions**:
1. Check trust level requirements in settings
2. Verify user is logged in
3. Check Rails logs:
   ```bash
   cd /var/discourse
   ./launcher logs app
   ```
4. Ensure MessageBus is working (check for WebSocket errors)

### CSS/Styling Issues

**Problem**: Plugin looks broken or unstyled

**Solutions**:
1. Clear Discourse cache:
   - Admin → Dashboard → "Clear cache" button
2. Rebuild assets:
   ```bash
   cd /var/discourse
   ./launcher enter app
   cd /var/www/discourse
   su discourse -c 'bundle exec rake assets:precompile'
   exit
   ```
3. Hard refresh browser (Ctrl+F5)

### Real-time Updates Not Working

**Problem**: Vote counts don't update in real-time

**Solutions**:
1. Check MessageBus is enabled in Discourse settings
2. Verify Redis is running:
   ```bash
   cd /var/discourse
   ./launcher enter app
   redis-cli ping
   # Should return "PONG"
   exit
   ```
3. Check browser extensions aren't blocking WebSockets
4. Test with browser console open to see connection errors

---

## Performance Considerations

### Database Indexes

The plugin creates appropriate indexes automatically. For large sites, monitor:

```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE tablename LIKE 'hoojah%';
```

### Caching

Vote counts are calculated on-demand. For high-traffic topics:

1. Consider caching vote counts in application cache
2. Monitor query performance in Admin → Dashboard → Performance

### MessageBus

The plugin uses MessageBus for real-time updates. This adds minimal overhead, but for very large sites:

1. Monitor Redis memory usage
2. Consider MessageBus channel optimization if needed

---

## Security Considerations

### Trust Levels

Set appropriate trust levels for voting:
- **TL0** (new users): May be vulnerable to abuse
- **TL1** (basic users): Good balance - recommended
- **TL2+**: Very restrictive, but secure

### Permissions

- Only admins and moderators can enable Hoojah by default
- Topic creators need explicit setting enabled
- Consider your community culture before allowing broad access

### Data Privacy

Vote data is stored in database:
- User votes are NOT anonymous
- Admins can query vote records
- Consider privacy policy implications

---

## Getting Help

### Support Channels

1. **GitHub Issues**: [Report bugs](https://github.com/hoojah/discourse-hujah/issues)
2. **Discourse Meta**: [Community support](https://meta.discourse.org/)
3. **Documentation**: Check README.md for API details

### Before Asking for Help

Provide this information:
- Discourse version (`Admin → Dashboard → Version`)
- Plugin version
- Installation method (Docker/development)
- Error messages from logs
- Steps to reproduce the issue

### Logs to Check

```bash
# Application logs
cd /var/discourse
./launcher logs app

# Rails console for debugging
./launcher enter app
cd /var/www/discourse
su discourse -c 'bundle exec rails console'
```

---

## Maintenance

### Regular Updates

Check for plugin updates monthly:

```bash
cd /var/discourse
./launcher rebuild app  # Pulls latest plugin code
```

### Monitoring

Monitor these metrics:
- Vote activity (database growth)
- MessageBus performance
- User engagement with polls

### Backups

Standard Discourse backups include plugin data:
- Admin → Backups → Create backup
- Includes all hoojah tables

---

## Production Checklist

Before going live with the plugin:

- [ ] Plugin installed and visible in Admin → Plugins
- [ ] Settings configured appropriately
- [ ] Test topic created with Hoojah enabled
- [ ] Voting tested with multiple users/trust levels
- [ ] Stance selector appears in composer
- [ ] Filter tabs work correctly
- [ ] Real-time updates functioning
- [ ] Mobile layout tested
- [ ] Performance acceptable
- [ ] Backups verified to include plugin data

---

## Additional Resources

- **Discourse Plugin Documentation**: https://meta.discourse.org/t/beginners-guide-to-creating-discourse-plugins/30515
- **Docker Manager**: https://meta.discourse.org/t/discourse-docker-manager/16066
- **Discourse Admin Guide**: https://meta.discourse.org/t/discourse-admin-quick-start-guide/47370

---

*Last updated: 2025-01-10*
