# Troubleshooting Hoojah Plugin on elect.io

## Infinite Loading Issue - Debugging Steps

### 1. Check Browser Console (CRITICAL - Do This First!)

The infinite loading spinner usually means JavaScript errors are preventing the app from initializing.

**Steps:**
1. Open your Discourse site (even with loading spinner)
2. Press **F12** (or Cmd+Option+I on Mac)
3. Click the **Console** tab
4. Look for RED error messages
5. Screenshot or copy any errors mentioning:
   - `hoojah` or `hujah`
   - `SyntaxError`
   - `Cannot find module`
   - `Ember`
   - `undefined is not a function`

### 2. Access elect.io Application Logs

**In elect.io dashboard:**
1. Navigate to your application logs
2. Filter or search for: `ERROR`, `hoojah`, or `Failed`
3. Look for errors in the last hour
4. Common error patterns to look for:
   ```
   SyntaxError: Unexpected token
   Failed to compile assets
   Ember.Application error
   LoadError: cannot load such file
   ```

### 3. Check Discourse Version Compatibility

Our plugin uses modern Ember.js syntax. You need:
- **Discourse 2.7.0+** (required)
- **Ember.js 3.13+** (for decorators)

**To check your version:**
- Look at the bottom of any Discourse page (footer)
- Or check elect.io dashboard for version info
- Or access: `https://your-site.elect.io/admin/upgrade`

### 4. Temporary Fix - Disable Plugin

**To verify the plugin is causing the issue:**

In your elect.io configuration (app.yml or similar):

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          # Temporarily disable hoojah plugin
          # - git clone https://github.com/hoojah/discourse-hujah.git
```

Then rebuild/redeploy. If Discourse loads normally, the plugin is the issue.

### 5. Common Issues & Solutions

#### Issue A: Ember Syntax Incompatibility

**Symptom:** Console error like `Unexpected token @` or `decorators not supported`

**Solution:** Your Discourse version might be too old. Upgrade to 2.7+ or we need to rewrite components without decorators.

#### Issue B: Missing Glimmer Components

**Symptom:** `Cannot find module @glimmer/component`

**Solution:** Need to use classic Ember components instead.

#### Issue C: Asset Compilation Failed

**Symptom:** Blank page, no console errors but network tab shows 404 for JS files

**Solution:** Assets didn't compile. Check build logs in elect.io.

#### Issue D: Plugin Loading Order

**Symptom:** `HoojahPoll is not defined` or similar

**Solution:** Dependencies loading in wrong order. Need to adjust plugin initialization.

### 6. elect.io Specific Commands

If elect.io provides SSH access or console access:

```bash
# Check if Discourse is running
ps aux | grep unicorn

# Check Rails logs
tail -f /var/www/discourse/log/production.log

# Test asset precompilation
cd /var/www/discourse
RAILS_ENV=production bundle exec rake assets:precompile

# Check for JavaScript errors in build
grep -i "error\|failed" /var/www/discourse/log/production.log | grep -i "asset\|javascript"
```

### 7. Quick Diagnostic Info to Collect

Please provide:

1. **Browser Console Output** (with errors)
2. **Discourse Version** (from footer or admin panel)
3. **Last 50 lines of application logs** from elect.io
4. **Does Discourse load without the plugin?** (yes/no after testing step 4)

### 8. Nuclear Option - Fresh Start

If nothing works, try installing a minimal version:

1. Remove the plugin completely
2. Verify Discourse works
3. Install just the backend (no JavaScript) to test
4. Gradually add features back

### Contact Info

Once you provide the diagnostic info above, we can:
- Fix JavaScript syntax for your Discourse version
- Rewrite components using compatible syntax
- Debug specific errors from your logs

---

**Next Steps:** Please run steps 1-4 and share the results!
