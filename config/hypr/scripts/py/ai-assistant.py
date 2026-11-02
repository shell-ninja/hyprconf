#!/usr/bin/env python3
"""
ai-assistant.py - CLI Agent Detector, Coordinator and Model Manager for Quickshell Console
Detects OpenCode, Claude Code, and Gemini CLI, provides models catalog, active model state, and commands.
"""

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path

HOME = Path.home()
SIDEBAR_CONFIG = HOME / ".local" / "share" / "hyprconf" / "sidebar.json"

def load_user_config():
    if SIDEBAR_CONFIG.is_file():
        try:
            return json.loads(SIDEBAR_CONFIG.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {}

def save_user_config(cfg):
    try:
        SIDEBAR_CONFIG.parent.mkdir(parents=True, exist_ok=True)
        SIDEBAR_CONFIG.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
        return True
    except Exception as e:
        print(f"Error saving sidebar config: {e}", file=sys.stderr)
        return False

def find_binary(names, extra_paths=None):
    if extra_paths:
        for p in extra_paths:
            exp = Path(os.path.expanduser(str(p)))
            if exp.is_file() and os.access(exp, os.X_OK):
                return str(exp)
    for name in names:
        w = shutil.which(name)
        if w:
            return w
    return ""

def get_opencode_models(binary_path):
    fallback_models = [
        "opencode/flint-40b-free",
        "opencode/deepseek-v4.1-flash-free",
        "opencode/glm-5.3-flash-free",
        "opencode/mimo-v2.6-flash-free",
        "opencode/nemotron-3.5-lightning-free",
        "opencode/nemotron-3.5-super-vl-free",
        "opencode/big-pickle",
        "opencode/beam-free",
        "google/gemini-3.8-flash",
        "google/gemini-3.7-flash",
        "google/gemini-3.6-flash",
        "google/gemini-3.5-flash",
        "google/gemini-2.5-pro",
        "google/gemini-2.5-flash-lite",
        "google/gemma-4-31b-it",
        "google/gemma-4-26b-a4b-it"
    ]
    if not binary_path:
        return fallback_models

    try:
        res = subprocess.run([binary_path, "models"], capture_output=True, text=True, timeout=3)
        lines = [l.strip() for l in res.stdout.strip().split("\n") if l.strip()]
        if lines:
            return lines
    except Exception:
        pass
    return fallback_models

def detect_opencode(saved_model=None):
    path = find_binary(
        ["opencode"],
        [
            HOME / ".opencode" / "bin" / "opencode",
            HOME / ".local" / "bin" / "opencode",
            "/usr/local/bin/opencode",
            "/usr/bin/opencode"
        ]
    )
    installed = bool(path)
    version = ""
    if installed:
        try:
            res = subprocess.run([path, "--version"], capture_output=True, text=True, timeout=2)
            version = res.stdout.strip() or res.stderr.strip()
        except Exception:
            version = "v2.x"

    models = get_opencode_models(path) if installed else []
    default_m = "opencode/flint-40b-free"
    if saved_model and (saved_model in models or not models):
        active_model = saved_model
    elif default_m in models:
        active_model = default_m
    elif models:
        active_model = models[0]
    else:
        active_model = default_m

    return {
        "id": "opencode",
        "name": "OpenCode",
        "tagline": "Autonomous Software Engineering CLI",
        "installed": installed,
        "path": path,
        "version": version or "v2.2.5",
        "install_cmd": "curl -fsSL https://opencode.ai/install.sh | bash",
        "default_model": default_m,
        "active_model": active_model,
        "models": models,
        "commands": [
            {"cmd": "/review", "name": "Review", "desc": "Analyze codebase for quality and bugs", "action": "Review this codebase for bugs, code quality, security vulnerabilities, and optimizations.", "is_subcmd": False},
            {"cmd": "/explain", "name": "Explain", "desc": "Explain architecture and logic flow", "action": "Explain the architecture, structure, and design patterns used in this codebase.", "is_subcmd": False},
            {"cmd": "/test", "name": "Tests", "desc": "Generate unit and integration tests", "action": "Analyze this codebase and write comprehensive unit tests with edge-case coverage.", "is_subcmd": False},
            {"cmd": "/fix", "name": "Fix", "desc": "Diagnose syntax, compile or logic errors", "action": "Diagnose any compile errors, syntax bugs, or broken logic in this project and propose fixes.", "is_subcmd": False},
            {"cmd": "/compact", "name": "Compact", "desc": "Compact session history to conserve context", "action": "/compact", "is_subcmd": False},
            {"cmd": "/models", "name": "Models", "desc": "List and switch available AI models", "action": "/models", "is_subcmd": False},
            {"cmd": "/help", "name": "Help", "desc": "Display OpenCode command parameters", "action": "--help", "is_subcmd": True}
        ]
    }

def detect_claude(saved_model=None):
    path = find_binary(
        ["claude", "claude-code"],
        [
            HOME / ".npm" / "bin" / "claude",
            HOME / ".local" / "bin" / "claude",
            HOME / ".npm-global" / "bin" / "claude",
            "/usr/local/bin/claude",
            "/usr/bin/claude"
        ]
    )
    installed = bool(path)
    version = ""
    if installed:
        try:
            res = subprocess.run([path, "--version"], capture_output=True, text=True, timeout=2)
            version = res.stdout.strip()
        except Exception:
            version = "v1.x"

    models = [
        "claude-3-7-sonnet",
        "claude-3-5-sonnet",
        "claude-3-5-haiku",
        "claude-opus-4-preview"
    ]
    active_model = saved_model if (saved_model and saved_model in models) else "claude-3-7-sonnet"

    return {
        "id": "claude",
        "name": "Claude Code",
        "tagline": "Agentic Coding Environment",
        "installed": installed,
        "path": path,
        "version": version or "Not Installed",
        "install_cmd": "npm install -g @anthropic-ai/claude-code",
        "default_model": "claude-3-7-sonnet",
        "active_model": active_model,
        "models": models,
        "commands": [
            {"cmd": "/review", "name": "PR Review", "desc": "Review git diff against main branch", "action": "/review", "is_subcmd": False},
            {"cmd": "/cost", "name": "Cost", "desc": "Display token usage and cost metrics", "action": "/cost", "is_subcmd": False},
            {"cmd": "/doctor", "name": "Doctor", "desc": "Check health, environment, and tools", "action": "doctor", "is_subcmd": True},
            {"cmd": "/init", "name": "Init Guide", "desc": "Initialize CLAUDE.md project guide", "action": "/init", "is_subcmd": False},
            {"cmd": "/compact", "name": "Compact", "desc": "Summarize conversation to free context", "action": "/compact", "is_subcmd": False},
            {"cmd": "/models", "name": "Models", "desc": "List and switch Claude models", "action": "/models", "is_subcmd": False},
            {"cmd": "/help", "name": "Help", "desc": "Display interactive command cheat sheet", "action": "--help", "is_subcmd": True}
        ]
    }

def detect_gemini(saved_model=None):
    path = find_binary(
        ["gemini", "gemini-cli", "google-genai", "agy"],
        [
            HOME / ".local" / "bin" / "gemini",
            HOME / ".local" / "bin" / "gemini-cli",
            HOME / ".gemini" / "bin" / "gemini",
            HOME / ".gemini" / "antigravity" / "bin" / "agy",
            "/usr/local/bin/gemini",
            "/usr/bin/gemini"
        ]
    )
    installed = bool(path)
    version = ""
    if installed:
        try:
            res = subprocess.run([path, "--version"], capture_output=True, text=True, timeout=2)
            version = res.stdout.strip()
        except Exception:
            version = "v1.x"

    models = [
        "gemini-2.5-pro",
        "gemini-2.5-flash",
        "gemini-3.8-flash",
        "gemini-1.5-pro"
    ]
    active_model = saved_model if (saved_model and saved_model in models) else "gemini-2.5-pro"

    return {
        "id": "gemini",
        "name": "Gemini CLI",
        "tagline": "Multimodal Developer CLI",
        "installed": installed,
        "path": path,
        "version": version or "Not Installed",
        "install_cmd": "pip install google-genai",
        "default_model": "gemini-2.5-pro",
        "active_model": active_model,
        "models": models,
        "commands": [
            {"cmd": "/code", "name": "Generate", "desc": "Produce idiomatic code for specifications", "action": "Write clean, idiomatic code for: ", "is_subcmd": False},
            {"cmd": "/tokens", "name": "Tokens", "desc": "Calculate input and output token consumption", "action": "Analyze token metrics for this prompt", "is_subcmd": False},
            {"cmd": "/models", "name": "Models", "desc": "Display available Gemini models", "action": "/models", "is_subcmd": False},
            {"cmd": "/system", "name": "System", "desc": "Define system persona and instructions", "action": "Set system persona: You are an expert Linux systems developer.", "is_subcmd": False},
            {"cmd": "/help", "name": "Help", "desc": "Show Gemini CLI options and flags", "action": "--help", "is_subcmd": True}
        ]
    }

def detect_all():
    cfg = load_user_config()
    active_models = cfg.get("active_models", {})

    opencode_info = detect_opencode(active_models.get("opencode"))
    claude_info = detect_claude(active_models.get("claude"))
    gemini_info = detect_gemini(active_models.get("gemini"))

    installed_map = {
        "opencode": opencode_info["installed"],
        "claude": claude_info["installed"],
        "gemini": gemini_info["installed"],
    }
    saved_engine = cfg.get("active_engine")
    if saved_engine in installed_map and installed_map[saved_engine]:
        active_id = saved_engine
    else:
        active_id = "opencode" if opencode_info["installed"] else ("claude" if claude_info["installed"] else ("gemini" if gemini_info["installed"] else "opencode"))

    return {
        "active_engine": active_id,
        "active_models": {
            "opencode": opencode_info["active_model"],
            "claude": claude_info["active_model"],
            "gemini": gemini_info["active_model"]
        },
        "engines": {
            "opencode": opencode_info,
            "claude": claude_info,
            "gemini": gemini_info
        }
    }

if __name__ == "__main__":
    if len(sys.argv) > 1:
        flag = sys.argv[1]
        if flag == "--set-model" and len(sys.argv) >= 4:
            engine = sys.argv[2]
            model = sys.argv[3]
            cfg = load_user_config()
            active_models = cfg.get("active_models", {})
            active_models[engine] = model
            cfg["active_models"] = active_models
            save_user_config(cfg)
            print(json.dumps({"status": "ok", "engine": engine, "active_model": model}, indent=2))
            sys.exit(0)
        elif flag == "--set-engine" and len(sys.argv) >= 3:
            engine = sys.argv[2]
            cfg = load_user_config()
            cfg["active_engine"] = engine
            save_user_config(cfg)
            print(json.dumps({"status": "ok", "active_engine": engine}, indent=2))
            sys.exit(0)
        elif flag == "--models" and len(sys.argv) >= 3:
            eng = sys.argv[2]
            data = detect_all()
            eng_data = data["engines"].get(eng, {})
            print(json.dumps({
                "engine": eng,
                "active_model": eng_data.get("active_model", ""),
                "models": eng_data.get("models", [])
            }, indent=2))
            sys.exit(0)

    data = detect_all()
    print(json.dumps(data, indent=2))
