# Better Clock

A minimal digital clock desktop widget for Noctalia with customizable time and date format strings.

## Plugin

| Field | Value |
| --- | --- |
| ID | `yugaaank/better-clock` |
| Entries | Desktop widget: `clock` |

## Usage

The Better Clock plugin adds a desktop widget that displays the current time and optionally the date below it. The widget updates every 30 seconds and uses Noctalia's built-in `formatTime()` function for locale-aware formatting.

### Desktop Widget

Add the widget to your widget order in Noctalia settings to display it on your desktop.

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `time_format` | `string` | `{:%H:%M}` | Luau date format for time, e.g. `{:%H:%M}` or `{:%I:%M %p}` |
| `date_format` | `string` | `{:%A, %B %d}` | Luau date format for date, e.g. `{:%A, %B %d}` |
| `show_date` | `bool` | `true` | Display the date below the time |