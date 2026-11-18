#!/usr/bin/env bash
# qs-media-downloader.sh — Launch or toggle Hyprconf Media Downloader

if pgrep -f "qs -c bar" >/dev/null 2>&1 && ! pgrep -f "qs -c island" >/dev/null 2>&1; then
    exec qs ipc -c bar call bar toggleMediaDownloader
fi

exec "$HOME/.hyprconf/hypr/scripts/sh/qs-island.sh" --media
