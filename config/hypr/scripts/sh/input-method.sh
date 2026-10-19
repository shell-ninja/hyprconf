#!/usr/bin/env bash
# input-method.sh — Switch/toggle input method (fcitx5 / ibus / hyprland) and trigger Dynamic Island OSD

toggle_fcitx5() {
    fcitx5-remote -t 2>/dev/null
    local state im label sub
    state=$(fcitx5-remote 2>/dev/null)
    im=$(fcitx5-remote -n 2>/dev/null)
    if [[ "$state" == "2" ]]; then
        label="${im:-Active IME}"
        sub="Fcitx5 • Active"
    else
        label="English (US)"
        sub="Fcitx5 • Inactive"
    fi
    qs ipc -c island call island showOsd "input" "0" "$label" "keyboard" "$sub" >/dev/null 2>&1 &
}

toggle_ibus() {
    local engine
    engine=$(ibus engine 2>/dev/null)
    qs ipc -c island call island showOsd "input" "0" "${engine:-IBus}" "keyboard" "IBus Input Method" >/dev/null 2>&1 &
}

toggle_hyprland() {
    hyprctl switchxkblayout current next >/dev/null 2>&1
    local layout
    layout=$(hyprctl devices -j 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    kbs = data.get('keyboards', [])
    main_kb = next((k for k in kbs if k.get('main')), kbs[0] if kbs else {})
    print(main_kb.get('active_keymap', 'English (US)'))
except Exception:
    print('English (US)')
" 2>/dev/null)
    qs ipc -c island call island showOsd "input" "0" "${layout:-English (US)}" "keyboard" "Keyboard Layout" >/dev/null 2>&1 &
}

# 1. Try fcitx5 if running
if command -v fcitx5-remote &>/dev/null && fcitx5-remote --check &>/dev/null; then
    toggle_fcitx5
    exit 0
fi

# 2. Try ibus if running
if command -v ibus &>/dev/null && pgrep -x ibus-daemon &>/dev/null; then
    toggle_ibus
    exit 0
fi

# 3. Default to Hyprland XKB
toggle_hyprland
