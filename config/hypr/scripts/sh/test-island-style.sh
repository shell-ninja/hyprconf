#!/usr/bin/env bash
# test-island-style.sh — Switch between the 3 Dynamic Island styles to test UI
# Styles: prism_blade, orbital, minimal_rail

STYLE="$1"

if [[ -z "$STYLE" ]]; then
    echo "Usage: test-island-style.sh [prism_blade | orbital | minimal_rail]"
    echo ""
    echo "Styles:"
    echo "  1) prism_blade   - Prism Blade Tactical HUD (Default)"
    echo "  2) orbital       - Orbital Satellite with Active Pearl"
    echo "  3) minimal_rail  - Minimal Dual-Rail Conveyor Stream"
    exit 1
fi

case "$STYLE" in
    prism_blade|prism|blade|1)
        STYLE_NAME="prism_blade"
        ;;
    orbital|2)
        STYLE_NAME="orbital"
        ;;
    minimal_rail|minimal|rail|3)
        STYLE_NAME="minimal_rail"
        ;;
    *)
        echo "Unknown style: $STYLE"
        echo "Choose one of: prism_blade, orbital, minimal_rail"
        exit 1
        ;;
esac

python3 -c "
import json, os
from pathlib import Path

user_cfg = Path(os.path.expanduser('~/.local/share/hyprconf/island.json'))
repo_cfg = Path(os.path.expanduser('~/.hyprconf/quickshell/island/config.json'))

for p in [user_cfg, repo_cfg]:
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        d = {}
        if p.exists():
            try:
                d = json.loads(p.read_text(encoding='utf-8'))
            except Exception:
                pass
        d['style'] = '$STYLE_NAME'
        p.write_text(json.dumps(d, indent=2) + '\n', encoding='utf-8')
    except Exception:
        pass
"

echo "Island style set to: $STYLE_NAME"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/qs-island.sh" --restart >/dev/null 2>&1 &
echo "Restarted Dynamic Island with style: $STYLE_NAME"
