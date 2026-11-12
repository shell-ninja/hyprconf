# Hyprconf Minimal Browser New Tab Theme

Synchronizes your browser New Tab page background with the active **Hyprconf GTK / Hyprland background color** (`colors.json` → `background`), updating automatically whenever your wallpaper or theme variant changes via `hypr-colors.py`.

---

## Chromium-Based Browsers
Works on **Brave**, **Brave Origin**, **Brave Beta/Nightly**, **Google Chrome**, **Chromium**, **Vivaldi**, **Microsoft Edge**, **Opera**, and **Ungoogled Chromium**:

1. Open your browser's extensions page (`chrome://extensions` or `brave://extensions`).
2. Toggle **Developer mode** ON.
3. Click **Load unpacked** and select:
   `~/.local/share/hyprconf/browser-ntp/chromium`
4. *(Optional)* Open **Details** and enable **Allow in Incognito**.

New tabs load the active theme immediately, and already-open New Tabs refresh automatically when focused.

---

## Firefox & Firefox-Based Browsers
Works on **Firefox**, **Zen Browser**, **Floorp**, **LibreWolf**, and **Waterfox**:

### Option A — Guided Opt-In Script
Run:
```bash
~/.local/share/hyprconf/browser-ntp/firefox/enable-firefox.sh
```
It discovers your browser profiles, lets you pick which profile(s) to enable, links `colors.css` + `hyprconf-ntp.css` into `<profile>/chrome/` (preserving any existing `userContent.css`), and enables `toolkit.legacyUserProfileCustomizations.stylesheets` in `user.js`. Restart the browser afterward to apply.

### Option B — Manual Setup
1. Open `about:config` and set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
2. Open `about:support` → **Profile Directory** → open or create the `chrome/` subfolder.
3. Symlink `~/.local/share/hyprconf/browser-ntp/firefox/colors.css` and `~/.local/share/hyprconf/browser-ntp/firefox/hyprconf-ntp.css` into `chrome/`, and ensure `chrome/userContent.css` contains:
   ```css
   @import url("hyprconf-ntp.css");
   ```
4. Restart your browser.
