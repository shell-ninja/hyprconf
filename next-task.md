# Hyprconf v1.0.3 — Roadmap & Feature Checklist

> **Target Version**: `v1.0.3`  
> **Milestone Focus**: Modular Plugins, Creative Canvas Studio & Deep Personalization

---

### 1. 🧩 Bar & Island Plugin Ecosystem
- [ ] **Unified Plugin Architecture**: Create a standardized lifecycle and IPC API for modular Quickshell widgets.
- [ ] **Dynamic Injection / Loading**: Allow users and third-party creators to drop custom plugins into a dedicated directory without touching core shell files.
- [ ] **Plugin Marketplace / Registry Foundation**: Metadata schema (`plugin.json`) defining author, hooks, dependencies, and settings UI.

---

### 2. 🏝️ New Dynamic Island Styles & Geometries
- [x] **Fresh Island Form Factors**: Screen-attached hardware notch (`mac_notch`) with seamless top-bezel attachment, inverted fillet ears ($R=6$), rounded bottom corners ($R=14$), and obsidian glass rim.
- [x] **Liquid Segment Workspaces Indicator**: Kinetic morphing pills with spring physics, active expansion (`[ 2 ]`), occupied status pips, hover scaling, and scroll-to-switch.
- [x] **Central Privacy Camera Lens**: Sensor glass aperture with specular catchlight and active LED states (screen recording/mic).
- [x] **Contextual Expansions**: Smooth adaptive audio spectrum waveform when music plays, notification banners, volume scroll, and click-to-expand.
- [x] **Style Switcher Integration**: Live 1-click preview and swap in Settings Studio (`IslandSection.qml`) and Welcome App (`welcome/shell.qml`).

---

### 3. 🎨 Adobe-Style Visual Canvas Studio (Lockscreen & Desktop Widgets)
- [ ] **Freeform WYSIWYG Editor**: Interactive drag-and-drop design canvas directly inside Quickshell Settings Studio.
- [ ] **Granular Object Customization**:
  - Live spatial controls: position $(x, y)$, sizing, alignment, and layering order (z-index).
  - Style properties: typography, obsidian glass rim opacity, accent blending, padding, and corner radius.
- [ ] **Live Instant Preview**: Real-time rendering of lockscreen and desktop widget layouts prior to saving.
- [ ] **Preset Export / Import**: Save and share custom canvas layouts as clean JSON templates.

---

### 4. 🎛️ User-Curated Dynamic Island Composition
- [ ] **Widget Slot Manager**: Let users select exactly what appears in their Island (weather, media, resource monitors, network, polkit, notifications).
- [ ] **Page Ordering & Visibility Toggles**: Enable/disable and reorder carousel pages (Control Center, Weather, Status, Audio).
- [ ] **Compact Notch Pill Selectors**: Custom rules for idle-notch indicators (e.g. choose between clock, active app icon, mini visualizer, or battery).

---

### 5. ⚡ Core Engine & Performance
- [ ] **State Isolation & Sync**: Persist all plugin and layout customizations to `~/.local/share/hyprconf/` with atomic writes.
- [ ] **Zero-Overhead Idle Optimization**: Ensure dynamic plugin registration doesn't add idle CPU/GPU wakeups.
