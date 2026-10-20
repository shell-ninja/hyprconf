#!/usr/bin/env python3
"""
Dynamic Weather Fetcher & Cache Manager for Hyprland / Quickshell
Fetches live weather and astronomy data from wttr.in using configured City and Country.
"""
import sys
import os
import json
import time
import urllib.request
import urllib.parse
from datetime import datetime
from pathlib import Path

HOME = Path(os.environ.get("HOME", "/home/shell-ninja"))
CONFIG_FILE = HOME / ".hyprconf/quickshell/lockscreen.json"
CACHE_FILE = HOME / ".hyprconf/hypr/.cache/weather_cache.json"
CACHE_TTL = 900  # 15 minutes


def load_location_config():
    """Load weather_city and weather_country from lockscreen.json."""
    city = ""
    country = ""
    try:
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                modules = data.get("modules", {})
                city = modules.get("weather_city", "") or ""
                country = modules.get("weather_country", "") or ""
    except Exception:
        pass

    # If city has a comma, split into city and country
    if "," in city and not country:
        parts = [p.strip() for p in city.split(",", 1)]
        city = parts[0]
        country = parts[1]

    return city.strip(), country.strip()


def save_location_config(city: str, country: str):
    """Save weather_city and weather_country into lockscreen.json."""
    try:
        CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
        data = {}
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
        if "modules" not in data:
            data["modules"] = {}
        data["modules"]["weather_city"] = city.strip()
        data["modules"]["weather_country"] = country.strip()
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)
        return True
    except Exception as e:
        print(f"Error saving location config: {e}", file=sys.stderr)
        return False


def get_cached_weather(max_age=CACHE_TTL):
    """Return cached weather data if still valid."""
    try:
        if CACHE_FILE.exists():
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                age = time.time() - data.get("timestamp", 0)
                if age < max_age:
                    return data
    except Exception:
        pass
    return None


def save_weather_cache(data):
    """Save weather data to cache file."""
    try:
        CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    except Exception:
        pass


def classify_condition(desc: str, code: str = "") -> str:
    """Classify weather condition description into animation archetype."""
    d = desc.lower()
    if any(k in d for k in ["thunder", "storm", "lightning"]):
        return "thunder"
    if any(k in d for k in ["snow", "blizzard", "sleet", "ice", "frost", "freez"]):
        return "snow"
    if any(k in d for k in ["rain", "drizzle", "shower"]):
        return "rain"
    if any(k in d for k in ["fog", "mist", "haze", "smoke", "dust", "sand"]):
        return "fog"
    if any(k in d for k in ["overcast", "cloud", "gloomy"]):
        return "cloudy"
    if any(k in d for k in ["sun", "clear"]):
        return "sunny"
    return "clear"


def parse_time_12h(time_str: str) -> float:
    """Convert '06:15 AM' to minutes from midnight (0.0 to 1440.0)."""
    try:
        t = datetime.strptime(time_str.strip(), "%I:%M %p")
        return float(t.hour * 60 + t.minute)
    except Exception:
        return 360.0  # default 6:00 AM


def calculate_day_progress(sunrise_str: str, sunset_str: str) -> float:
    """Calculate progress (0.0 to 1.0) along the daylight arc."""
    try:
        now = datetime.now()
        cur_min = float(now.hour * 60 + now.minute)
        sr_min = parse_time_12h(sunrise_str)
        ss_min = parse_time_12h(sunset_str)
        if ss_min <= sr_min:
            ss_min += 720.0
        if cur_min < sr_min:
            return 0.0
        if cur_min > ss_min:
            return 1.0
        return max(0.0, min(1.0, (cur_min - sr_min) / (ss_min - sr_min)))
    except Exception:
        return 0.5


def fetch_weather(city: str, country: str):
    """Fetch live structured weather data from wttr.in using format=j1."""
    if not city and not country:
        return {
            "configured": False,
            "city": "",
            "country": "",
            "location": "Location Not Set",
            "text": "Location Not Set",
            "temp_C": "--",
            "temp_F": "--",
            "feels_like_C": "--",
            "condition": "Please enter City & Country",
            "weather_category": "sunny",
            "humidity": "--",
            "wind_speed": "--",
            "wind_dir": "--",
            "pressure": "--",
            "visibility": "--",
            "uv_index": "--",
            "sunrise": "06:00 AM",
            "sunset": "06:00 PM",
            "moon_phase": "New Moon",
            "day_progress": 0.5,
            "is_day": True,
            "timestamp": time.time()
        }

    loc_str = f"{city},{country}" if (city and country) else (city or country)
    encoded_loc = urllib.parse.quote(loc_str)
    url = f"https://wttr.in/{encoded_loc}?format=j1"

    req = urllib.request.Request(
        url,
        headers={"User-Agent": "curl/8.0"}
    )

    try:
        with urllib.request.urlopen(req, timeout=4.0) as resp:
            raw = json.loads(resp.read().decode("utf-8"))
            cc = raw["current_condition"][0]
            weather_day = raw["weather"][0]
            astro = weather_day.get("astronomy", [{}])[0]

            temp_c = str(cc.get("temp_C", "--"))
            temp_f = str(cc.get("temp_F", "--"))
            feels_c = str(cc.get("FeelsLikeC", temp_c))
            desc = cc.get("weatherDesc", [{}])[0].get("value", "Clear")
            humidity = str(cc.get("humidity", "--"))
            wind_kph = str(cc.get("windspeedKmph", "--"))
            wind_dir = str(cc.get("winddir16Point", "--"))
            pressure = str(cc.get("pressure", "--"))
            visibility = str(cc.get("visibility", "--"))
            uv_index = str(cc.get("uvIndex", "--"))
            code = str(cc.get("weatherCode", "113"))
            sunrise = str(astro.get("sunrise", "06:00 AM"))
            sunset = str(astro.get("sunset", "06:00 PM"))
            moon_phase = str(astro.get("moon_phase", "Waxing Gibbous"))

            cat = classify_condition(desc, code)
            day_progress = calculate_day_progress(sunrise, sunset)
            now_h = datetime.now().hour
            is_day = 6 <= now_h < 18

            location_display = f"{city}, {country}" if (city and country) else (city or country)
            summary_text = f"{temp_c}°C • {desc}"

            data = {
                "configured": True,
                "city": city,
                "country": country,
                "location": location_display,
                "text": summary_text,
                "temp_C": temp_c,
                "temp_F": temp_f,
                "feels_like_C": feels_c,
                "condition": desc,
                "weather_category": cat,
                "weather_code": code,
                "humidity": humidity,
                "wind_speed": wind_kph,
                "wind_dir": wind_dir,
                "pressure": pressure,
                "visibility": visibility,
                "uv_index": uv_index,
                "sunrise": sunrise,
                "sunset": sunset,
                "moon_phase": moon_phase,
                "day_progress": day_progress,
                "is_day": is_day,
                "timestamp": time.time()
            }
            save_weather_cache(data)
            return data
    except Exception as e:
        # Fall back to stale cache if available
        cached = get_cached_weather(max_age=86400 * 7)
        if cached:
            return cached
        loc_display = f"{city}, {country}" if (city and country) else (city or country or "Offline")
        return {
            "configured": True,
            "city": city,
            "country": country,
            "location": loc_display,
            "text": f"20°C • Offline ({loc_display})",
            "temp_C": "20",
            "temp_F": "68",
            "feels_like_C": "20",
            "condition": "Offline / Cache Unavailable",
            "weather_category": "cloudy",
            "weather_code": "116",
            "humidity": "50",
            "wind_speed": "10",
            "wind_dir": "N",
            "pressure": "1013",
            "visibility": "10",
            "uv_index": "3",
            "sunrise": "06:00 AM",
            "sunset": "06:00 PM",
            "moon_phase": "Waxing Gibbous",
            "day_progress": 0.5,
            "is_day": True,
            "timestamp": time.time()
        }


def main():
    force = "--force" in sys.argv
    as_json = "--json" in sys.argv

    # Check for set-location command
    if "--set-location" in sys.argv:
        idx = sys.argv.index("--set-location")
        c = sys.argv[idx + 1] if idx + 1 < len(sys.argv) else ""
        co = sys.argv[idx + 2] if idx + 2 < len(sys.argv) else ""
        save_location_config(c, co)
        data = fetch_weather(c, co)
        print(json.dumps(data) if as_json else data.get("text", ""))
        return

    city, country = load_location_config()

    if "--city" in sys.argv:
        idx = sys.argv.index("--city")
        if idx + 1 < len(sys.argv):
            city = sys.argv[idx + 1]
    if "--country" in sys.argv:
        idx = sys.argv.index("--country")
        if idx + 1 < len(sys.argv):
            country = sys.argv[idx + 1]

    data = None
    if not force:
        cached = get_cached_weather(CACHE_TTL)
        if cached and cached.get("city") == city and cached.get("country") == country:
            data = cached

    if not data:
        data = fetch_weather(city, country)

    if as_json:
        print(json.dumps(data))
    else:
        print(data.get("text", "Weather Not Set"))


if __name__ == "__main__":
    main()
