# Arch Updater

Check pacman, AUR and Flatpak for updates from the bar, with an estimated
download size and an Arch news heads-up before you upgrade. **Update** runs
the upgrade in one of two modes (the **Update mode** setting): a terminal
window with the usual interactive upgrade — prompts and the PKGBUILD review
work as normal (the default, same behavior as before), or fully in the
background — polkit asks for your password, the panel shows a live log tail
and a progress bar, and a notification reports the result. Either way the
run is logged and recorded in an update history with per-package rollback.

## Plugin

| Field | Value |
| --- | --- |
| ID | `yuuto/arch-updater` |
| Entries | Bar widget: `widget`; panel: `panel`; service: `service`; launcher: `launcher` |
| Launcher Prefix | `/arch` |

## Requirements

- `pacman-contrib` on `PATH` (for `checkupdates` and `pactree`), required.
- `pacman`, `sh`, `awk`, `sed`, `grep`, `tail`, `head`, `tee`, `wc`, `date`,
  `rm`, `install`, `test`, `cat`, `kill` and `uname`, required — base tools
  from any standard Arch install (coreutils and friends), used to run and
  parse the checks, build the download size estimate, check the running
  kernel, follow and open the update log, install the optional polkit rule,
  and detect whether a terminal update run's process is still alive.
- `pkexec` (polkit) with an authentication agent, required for the
  background update mode and for rollback. Noctalia's built-in polkit agent
  works out of the box.
- `yay` or `paru` on `PATH`, optional, for the AUR check and update.
  Auto-detected by default, see the **AUR helper** setting.
- `flatpak`, optional, for the Flatpak check and update.
- `xdg-open`, optional, to open a package page or the Arch news page.
- `less`, plus `sudo` and a terminal emulator, for the terminal update mode
  (the default), the **Retry in terminal** fallback and the **Open full
  log** viewer: Noctalia's own terminal detection (`$TERMINAL`, then the
  common emulators), or the one named in the **Terminal** setting.

A missing optional tool is skipped, not treated as an error.

## Usage

Add the `widget` bar widget from Noctalia's widget picker. Left click opens
the panel, right click checks for updates now, middle click opens the
widget's own settings. You can also open the panel directly or bind it in
your compositor:

```sh
noctalia msg panel-toggle yuuto/arch-updater:panel
```

The panel groups pending packages by source (Pacman, AUR, Flatpak). Click a
source row to expand it into its packages. Each package row has an ignore
button (see **Ignored packages**), a copy button (name and versions) and an
open button (its page on archlinux.org, the AUR, or Flathub). The history
button next to **Check** opens the plugin's changelog, so you can see what
changed in each release without leaving the panel. It also opens on its own
once an update finishes, unless you turn that off with the **Show changelog
after updating** setting.

**Update** follows the **Update mode** setting:

- **In a terminal window** (default): opens a terminal running the usual
  interactive upgrade — `sudo pacman -Syu` or the AUR helper without any
  auto-answer flags, so prompts, conflicts and the PKGBUILD review work
  exactly as on the command line. The output is `tee`'d into the update
  log, so the panel still shows the live tail, the progress bar and the
  bar-widget percentage, and the run still lands in the update history.
- **In the background**: pkexec raises the polkit password dialog,
  everything else is non-interactive (`--noconfirm`, and for the AUR helper
  `--skipreview` / the `--answer*` flags), so any remaining question gets
  its default answer. The run is spawned detached and survives a shell
  restart: a restarted engine re-attaches to an unfinished log and keeps
  showing progress. A background run that cannot proceed non-interactively
  stops cleanly with a non-zero exit before touching the system; a failed
  run keeps its log on screen and offers **Retry in terminal**.

When a run ends you get a notification and an automatic re-check.
**Dismiss** clears the pending list until the next check. **Check Updates**
queries all sources.

Type `/arch` in the launcher for quick actions (check, update, open news),
or `/arch <text>` to fuzzy-search the packages from the last check.
Activating a result opens that package's page.

### Update history and rollback

A strip at the bottom of the panel has one segment per recorded run (the
last 15), oldest on the left; rollbacks get their own segments. Hover shows
the date and package count, click opens the run's package list: each row
shows `name from → to` with a rollback button (a second click confirms),
and the header offers rolling back the whole run in one transaction.

Rollback installs the old package files straight from the caches
(`/var/cache/pacman/pkg`, paru's/yay's build dirs) with
`pkexec pacman -U`: the chosen version is installed directly, no stepping
through intermediate upgrades. Dependencies updated in the same run ride
along in the same transaction (resolved with `pactree` against the run's
package list), so a program and its libraries move back together.
`--nodeps` is never used: a downgrade that would break another package's
versioned dependencies makes pacman refuse the whole transaction before
anything changes. When a run's package list is opened, the engine probes
the caches and reverse dependencies: packages whose old file is gone are
greyed out, and the rollback tooltip warns how many installed packages
require the one being rolled back. Flatpak entries are shown but not
rollbackable.

Before a run is recorded, `pacman -Q` confirms which packages actually
changed: anything declined during an interactive terminal run is left out
of the entry, so the history never offers to "undo" an update that did not
happen. Failed runs are not recorded.

### Activity graph

The optional activity graph (off by default, **Show activity graph**)
tracks the pending-update count across recent checks and when you last
updated, drawn as a small trend line above the history strip. Hovering the
dot axis under the line highlights a check and describes it (count, time,
or "Updated" for the check that verified a run). Turning the setting off
also stops recording the data.

### Ignored packages

Three ignore sources are merged and shown in an expandable **Ignored**
section at the bottom of the package list:

- **Panel-managed.** The ignore button on a package row adds it to a list
  kept in the plugin's data directory. These entries have a restore button
  in the Ignored section.
- **The `ignore_packages` setting.** Shown with a *settings* tag; clicking
  the tag opens the plugin's settings.
- **`pacman.conf`'s `IgnorePkg`.** Update checkers report these packages
  with an `[ignored]` marker; they are shown with a *pacman.conf* tag and
  are managed only in that file. The plugin never edits `pacman.conf`.

Ignored packages are excluded from the pending count and passed as
`--ignore` to the update run in both modes (Flatpak refs are filtered out
of `flatpak update` the same way).

### One polkit password per run

`pkexec` authenticates every pacman transaction separately, so a background
update that syncs databases and installs AUR builds can raise several
password dialogs. Until a keep-authorization polkit rule is installed, the
panel shows a hint line with an **Ask once** button (only in background
mode — the terminal mode goes through `sudo` and never hits this): it
installs, through one `pkexec` call you confirm, a rule that keeps a
successful authentication for ~5 minutes — like `sudo`'s timestamp.

**Scope, stated plainly:** the rule grants `AUTH_ADMIN_KEEP` for *any*
`pkexec`-launched `/usr/bin/pacman` call made from an active local session
of a `wheel` member — not only this plugin's calls — comparable to a
manually added NOPASSWD-with-timeout sudoers line. It is strictly opt-in,
the same wording appears in the install button's tooltip, and it can be
removed at any time:

```sh
sudo rm /etc/polkit-1/rules.d/49-arch-updater-pacman.rules
```

The rule text ships in `polkit/49-arch-updater-pacman.rules` and can also
be installed by hand:

```sh
sudo install -Dm644 polkit/49-arch-updater-pacman.rules /etc/polkit-1/rules.d/49-arch-updater-pacman.rules
```

The hint can be hidden with the **Hide the polkit rule suggestion**
setting.

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `aur_helper` | `select` | `auto` | Which AUR helper to use: auto-detect (yay, then paru), `yay`, `paru`, a custom command, or off. |
| `aur_check_cmd` | `string` | *(empty)* | Custom AUR check command, only used when `aur_helper` is `custom`. Must print `name oldver -> newver` per line. |
| `flatpak_enabled` | `bool` | `true` | Also check and update Flatpak. Skipped automatically when `flatpak` isn't installed. |
| `ignore_packages` | `string_list` | *(empty)* | Package names excluded from the count and passed as `--ignore` on update, on top of the panel-managed list and `pacman.conf`'s `IgnorePkg`. |
| `auto_check_hours` | `int` | `0` | Check automatically every N hours. `0` never checks on its own. |
| `notify_on_updates` | `bool` | `true` | Send a desktop notification when a check finds packages to upgrade. |
| `show_download_size` | `bool` | `true` | Show the estimated pacman download size (`pacman -Si`) in the panel. |
| `check_arch_news` | `bool` | `true` | Check the Arch Linux news feed and flag unread posts. |
| `check_reboot_needed` | `bool` | `true` | Flag when the running kernel is no longer installed on disk. |
| `show_activity_graph` | `bool` | `false` | Track pending-update counts across checks and show them as a small graph. Off also stops recording. |
| `activity_history_length` | `int` | `10` | How many recent checks the activity graph keeps (3–30). |
| `update_mode` | `select` | `terminal` | How **Update** runs the upgrade: in a terminal window (interactive, like before) or in the background (non-interactive). |
| `rollback_auto_ignore` | `bool` | `false` | After a successful rollback, add the rolled-back packages to the plugin's ignore list. |
| `hide_polkit_hint` | `bool` | `false` | Hide the panel line offering to install the polkit keep-authorization rule. |
| `log_lines` | `int` | `14` | How many of the latest update-log lines the panel shows during a run (6–30). |
| `terminal` | `string` | *(empty)* | Terminal command for terminal-mode updates, the retry fallback and the log viewer. Empty uses Noctalia's detection. |
| `update_cmd` | `string` | *(empty)* | Full override for the background update command. Empty builds it from the settings above, running pacman through `pkexec`. |
| `glyph` | `glyph` | `package` | The glyph shown for the widget on the bar. |
| `show_count` | `bool` | `true` | Show the pending-update count next to the bar glyph. |
| `hide_on_empty` | `bool` | `false` | Hide the widget entirely when there is nothing to show. |

## IPC

```sh
noctalia msg plugin yuuto/arch-updater:service all check
noctalia msg plugin yuuto/arch-updater:service all update
noctalia msg plugin yuuto/arch-updater:service all update_background
noctalia msg plugin yuuto/arch-updater:service all update_terminal
noctalia msg plugin yuuto/arch-updater:service all dismiss
noctalia msg plugin yuuto/arch-updater:service all ignore:NAME
noctalia msg plugin yuuto/arch-updater:service all unignore:NAME
```

`update` follows the **Update mode** setting; `update_background` and
`update_terminal` force one mode. `ignore:NAME` / `unignore:NAME` edit the
panel-managed ignore list.

## Notes

- **Commands spawned.** Checks: `checkupdates`; the AUR helper's `-Qua` (or
  your custom command); `flatpak list` / `flatpak remote-ls --updates`
  (combined with `sed`/`awk`); `pacman -Si` piped through `awk` for the
  download size; `test -d` against `uname -r` for the reboot check. Update:
  a detached `sh` running `pkexec pacman -Syu` or the AUR helper with
  `--sudo pkexec`, then optionally `flatpak update` — all output redirected
  to the update log, which the engine follows with `tail`/`grep`. The
  terminal mode runs the interactive equivalents (`sudo pacman -Syu`, the
  helper without auto-answers) under your terminal, `tee`'d into the same
  log. Rollback: `pactree` to resolve same-run dependencies, a shell glob
  over the package caches to find the old files, `pkexec pacman -U` to
  install them, and `pactree -rd1` piped through `wc` for the
  reverse-dependency warning. After a successful run, `pacman -Q` verifies
  which packages actually changed before the history entry is written.
  **Open full log** shows the log with `less` in your terminal.
- **Privileges.** Escalation happens only through polkit: `pkexec pacman`
  for repo packages and rollback, and the AUR helper escalates its install
  steps through `pkexec` itself (`--sudo pkexec`). AUR builds run
  unprivileged as usual. The terminal mode escalates through `sudo` inside
  your terminal, as a manual upgrade would. The optional **Ask once**
  button installs the shipped polkit rule via one user-confirmed
  `pkexec install` call; nothing else touches system configuration, and
  `pacman.conf` is never modified.
- **Network.** `checkupdates`, the AUR helper and the Flatpak check contact
  mirrors, the AUR RPC, or a Flatpak remote, same as the corresponding
  upgrade would. The Arch news check fetches `archlinux.org/feeds/news/`
  once at startup and then every 6 hours.
- **Files written.** All in the plugin's data directory: `update.log` (the
  current/last run, with `::START`/`::EXIT` markers), `run_meta.json` (the
  current run's kind and package list, so a restarted shell can keep
  tracking it; removed when the run ends), `runs.json` (the update history,
  last 15 successful runs), `history_state.json` (the activity graph data),
  `ignore.json` (the panel-managed ignore list), `news_state.json` (the
  last read news post), a staged copy of the polkit rule, and a marker
  recording that the rule was installed (`/etc/polkit-1/rules.d` is not
  readable by regular users on Arch, so presence can't always be probed
  directly).
- **Stuck-run guard.** A *background* run whose log stops growing for 30
  minutes is declared failed; the panel then offers the terminal fallback.
  Terminal runs are exempt — log silence there can just be you reading a
  PKGBUILD diff. Unfinished logs older than 6 hours are not resumed after
  a restart.
- **Sizes are pacman-only.** AUR and Flatpak downloads aren't sized. Most
  AUR packages build from source, where a download size wouldn't mean much.
- **`-git` (devel) packages and rollback.** After rolling one back, the
  next check usually does *not* list it as an update: paru/yay track devel
  packages by the last built commit, not the installed version. Move
  forward again through the rollback's own history segment, or with
  `paru -S <package>`. Regular repo packages reappear as pending on the
  very next check.

## Credits

Ported from the v4 QML "Arch Updater" plugin (MIT), rebuilt for v5's Luau
plugin API. Background update mode, ignore management, the polkit
integration, and the update history with rollback contributed by
[UmedjonBA](https://github.com/UmedjonBA).

## License

MIT.
