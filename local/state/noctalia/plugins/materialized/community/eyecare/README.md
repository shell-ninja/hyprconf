# Eye-Care Reminders

Periodically reminds you to take breaks using the 20-20-20 rule to reduce eye strain.

## Plugin

| Field | Value |
| --- | --- |
| ID | `apex077/eyecare` |
| Entries | Bar widget: `eyecare-widget`; service: `eyecare-service` |

## Requirements

- `dbus-monitor` on `PATH` (optional, for automatic system idle and screensaver lock detection).
- A system audio player on `PATH` (e.g., `canberra-gtk-play`, `paplay`, `pw-play`, or `aplay`) to hear sound cues.

## Usage

The **Eye-Care Reminders** plugin provides a status bar widget that displays either the active time countdown or the break duration.

- **Active State**: Shows the remaining active screen time (e.g., `20:00`). Clicking the widget manually starts a break.
- **Break State**: Shows the remaining break duration (e.g., `Break: 20s`). Look 20 feet away at an object during this time. Clicking the widget aborts the break early.
- **Idle State**: Automatically pauses active timer accumulation and resets it if the user remains idle for the duration of a break.
- **Right-Click**: Resets the active/break timer back to its initial state.

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `active_duration_minutes` | `int` | `20` | Active screen time before triggering a break (minutes) |
| `break_duration_seconds` | `int` | `20` | Required duration for eye-care breaks (seconds) |
| `enable_sound` | `bool` | `true` | Play notification sound when breaks start or finish (also requires Noctalia global sounds to be enabled) |
| `enable_notifications` | `bool` | `true` | Show system-level notifications for reminders |

## IPC

The service listens for compositor idle events. You can configure compositor hooks to notify the service when the system goes idle or resumes:

```sh
noctalia msg plugin apex077/eyecare:eyecare-service all idled
noctalia msg plugin apex077/eyecare:eyecare-service all active
```

You can also send custom trigger/reset events to the service:

```sh
noctalia msg plugin apex077/eyecare:eyecare-service all trigger-break
noctalia msg plugin apex077/eyecare:eyecare-service all finish-break
noctalia msg plugin apex077/eyecare:eyecare-service all reset
```

## Notes

- **Zero-Config Idle Detection**: If `dbus-monitor` is installed, the service automatically monitors screensaver and login lock session state without manual compositor configuration.
- **Sound Players**: Sound notifications use Noctalia's native sound API if available, falling back to system audio players (`canberra-gtk-play`, `paplay`, `pw-play`, `aplay`), while respecting Noctalia's global sound settings.
- **Grace Period**: When starting a break, a grace period (default 10 seconds or the break duration, whichever is smaller) protects against accidental inputs aborting the break immediately.
