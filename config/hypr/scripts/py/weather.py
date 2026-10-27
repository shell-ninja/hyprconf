#!/usr/bin/env python3
"""
Dynamic Weather Fetcher & Cache Manager for Hyprland / Quickshell
Fetches live weather and astronomy data from Open-Meteo (with wttr.in fallback)
using configured City and Country. Generates current conditions and 7-day forecast.
"""
import sys
import os
import json
import time
import urllib.request
import urllib.parse
from datetime import datetime
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
CONFIG_FILE = HOME / ".hyprconf/quickshell/lockscreen.json"
CACHE_FILE = HOME / ".hyprconf/hypr/.cache/weather_cache.json"
CACHE_TTL = 900  # 15 minutes

WMO_MAP = {
    0: ("Clear sky", "sunny"),
    1: ("Mainly clear", "sunny"),
    2: ("Partly cloudy", "cloudy"),
    3: ("Overcast", "cloudy"),
    45: ("Foggy", "fog"),
    48: ("Depositing rime fog", "fog"),
    51: ("Light drizzle", "rain"),
    53: ("Moderate drizzle", "rain"),
    55: ("Dense drizzle", "rain"),
    56: ("Light freezing drizzle", "snow"),
    57: ("Dense freezing drizzle", "snow"),
    61: ("Slight rain", "rain"),
    63: ("Moderate rain", "rain"),
    65: ("Heavy rain", "rain"),
    66: ("Light freezing rain", "snow"),
    67: ("Heavy freezing rain", "snow"),
    71: ("Slight snow fall", "snow"),
    73: ("Moderate snow fall", "snow"),
    75: ("Heavy snow fall", "snow"),
    77: ("Snow grains", "snow"),
    80: ("Slight rain showers", "rain"),
    81: ("Moderate rain showers", "rain"),
    82: ("Violent rain showers", "rain"),
    85: ("Slight snow showers", "snow"),
    86: ("Heavy snow showers", "snow"),
    95: ("Thunderstorm", "thunder"),
    96: ("Thunderstorm with slight hail", "thunder"),
    99: ("Thunderstorm with heavy hail", "thunder"),
}


def deg_to_compass(deg: float) -> str:
    """Convert degree heading (0-360) to 16-point compass string."""
    try:
        val = int((float(deg) / 22.5) + 0.5)
        points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        return points[(val % 16)]
    except Exception:
        return "N"


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


def fetch_open_meteo(city: str, country: str):
    """Fetch structured live weather + 7-day forecast from Open-Meteo."""
    query = f"{city}, {country}" if (city and country) else (city or country)
    geo_url = f"https://geocoding-api.open-meteo.com/v1/search?name={urllib.parse.quote(query)}&count=1"
    req_geo = urllib.request.Request(geo_url, headers={"User-Agent": "Hyprland-Quickshell/1.0"})

    with urllib.request.urlopen(req_geo, timeout=3.5) as resp:
        geo_data = json.loads(resp.read().decode("utf-8"))
        results = geo_data.get("results")
        if not results:
            # Try just city name if compound search yielded no result
            if city and country:
                fallback_geo = f"https://geocoding-api.open-meteo.com/v1/search?name={urllib.parse.quote(city)}&count=1"
                req_fb = urllib.request.Request(fallback_geo, headers={"User-Agent": "Hyprland-Quickshell/1.0"})
                with urllib.request.urlopen(req_fb, timeout=3.0) as resp_fb:
                    results = json.loads(resp_fb.read().decode("utf-8")).get("results")

        if not results:
            raise ValueError(f"Location '{query}' could not be resolved.")

        loc = results[0]
        lat = loc["latitude"]
        lon = loc["longitude"]
        res_city = loc.get("name", city)
        res_country = loc.get("country", country)

    fc_url = (
        f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}"
        f"&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure"
        f"&daily=weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,uv_index_max,precipitation_probability_max,precipitation_sum"
        f"&timezone=auto"
    )
    req_fc = urllib.request.Request(fc_url, headers={"User-Agent": "Hyprland-Quickshell/1.0"})

    with urllib.request.urlopen(req_fc, timeout=4.0) as resp:
        fc = json.loads(resp.read().decode("utf-8"))

    cur = fc.get("current", {})
    daily = fc.get("daily", {})

    temp_c_val = cur.get("temperature_2m", 20.0)
    feels_c_val = cur.get("apparent_temperature", temp_c_val)
    temp_c = str(round(temp_c_val))
    temp_f = str(round(temp_c_val * 9 / 5 + 32))
    feels_c = str(round(feels_c_val))
    feels_f = str(round(feels_c_val * 9 / 5 + 32))

    wmo_code = cur.get("weather_code", 0)
    desc, cat = WMO_MAP.get(wmo_code, ("Clear sky", "sunny"))
    is_day = bool(cur.get("is_day", 1))

    humidity = str(round(cur.get("relative_humidity_2m", 50)))
    wind_kph = str(round(cur.get("wind_speed_10m", 10)))
    wind_deg = cur.get("wind_direction_10m", 0)
    wind_dir = deg_to_compass(wind_deg)
    pressure = str(round(cur.get("surface_pressure", 1013)))

    # Parse daily 7-day forecast
    forecast_list = []
    time_arr = daily.get("time", [])
    max_t_arr = daily.get("temperature_2m_max", [])
    min_t_arr = daily.get("temperature_2m_min", [])
    code_arr = daily.get("weather_code", [])
    pop_arr = daily.get("precipitation_probability_max", [])
    uv_arr = daily.get("uv_index_max", [])
    sunrise_arr = daily.get("sunrise", [])
    sunset_arr = daily.get("sunset", [])

    sunrise_str = "06:00 AM"
    sunset_str = "06:00 PM"
    uv_index = "3"

    for i in range(len(time_arr)):
        date_str = time_arr[i]
        try:
            dt = datetime.strptime(date_str, "%Y-%m-%d")
            day_name = "Today" if i == 0 else ("Tomorrow" if i == 1 else dt.strftime("%a"))
            day_full = dt.strftime("%A")
            display_date = dt.strftime("%b %d")
        except Exception:
            day_name = f"Day {i+1}"
            day_full = day_name
            display_date = date_str

        code = code_arr[i] if i < len(code_arr) else 0
        d_desc, d_cat = WMO_MAP.get(code, ("Clear", "sunny"))
        t_max_c = round(max_t_arr[i]) if i < len(max_t_arr) else 20
        t_min_c = round(min_t_arr[i]) if i < len(min_t_arr) else 10
        t_max_f = round(t_max_c * 9 / 5 + 32)
        t_min_f = round(t_min_c * 9 / 5 + 32)
        pop = round(pop_arr[i]) if (i < len(pop_arr) and pop_arr[i] is not None) else 0
        uv = round(uv_arr[i]) if (i < len(uv_arr) and uv_arr[i] is not None) else 3

        if i == 0:
            uv_index = str(uv)
            if i < len(sunrise_arr) and sunrise_arr[i]:
                try:
                    sunrise_str = datetime.fromisoformat(sunrise_arr[i]).strftime("%I:%M %p")
                except Exception:
                    pass
            if i < len(sunset_arr) and sunset_arr[i]:
                try:
                    sunset_str = datetime.fromisoformat(sunset_arr[i]).strftime("%I:%M %p")
                except Exception:
                    pass

        forecast_list.append({
            "date": date_str,
            "display_date": display_date,
            "day": day_name,
            "day_full": day_full,
            "temp_max_C": str(t_max_c),
            "temp_min_C": str(t_min_c),
            "temp_max_F": str(t_max_f),
            "temp_min_F": str(t_min_f),
            "condition": d_desc,
            "weather_category": d_cat,
            "weather_code": str(code),
            "pop": int(pop),
            "uv": int(uv),
        })

    day_progress = calculate_day_progress(sunrise_str, sunset_str)
    location_display = f"{res_city}, {res_country}" if (res_city and res_country) else (res_city or query)
    summary_text = f"{temp_c}°C • {desc}"

    return {
        "configured": True,
        "city": res_city,
        "country": res_country,
        "location": location_display,
        "text": summary_text,
        "temp_C": temp_c,
        "temp_F": temp_f,
        "feels_like_C": feels_c,
        "feels_like_F": feels_f,
        "condition": desc,
        "weather_category": cat,
        "weather_code": str(wmo_code),
        "humidity": humidity,
        "wind_speed": wind_kph,
        "wind_dir": wind_dir,
        "pressure": pressure,
        "visibility": "10",
        "uv_index": uv_index,
        "sunrise": sunrise_str,
        "sunset": sunset_str,
        "moon_phase": "Waxing Gibbous",
        "day_progress": day_progress,
        "is_day": is_day,
        "forecast_7days": forecast_list,
        "timestamp": time.time()
    }


def fetch_wttr(city: str, country: str):
    """Fetch weather from wttr.in as reliable fallback."""
    loc_str = f"{city},{country}" if (city and country) else (city or country)
    encoded_loc = urllib.parse.quote(loc_str)
    url = f"https://wttr.in/{encoded_loc}?format=j1"
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8.0"})

    with urllib.request.urlopen(req, timeout=4.0) as resp:
        raw = json.loads(resp.read().decode("utf-8"))
        cc = raw["current_condition"][0]
        weather_days = raw.get("weather", [{}])
        weather_day = weather_days[0]
        astro = weather_day.get("astronomy", [{}])[0]

        temp_c = str(cc.get("temp_C", "--"))
        temp_f = str(cc.get("temp_F", "--"))
        feels_c = str(cc.get("FeelsLikeC", temp_c))
        feels_f = str(round(float(feels_c) * 9 / 5 + 32)) if feels_c.replace("-", "").isdigit() else temp_f
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

        forecast_list = []
        for i, w in enumerate(weather_days):
            date_str = w.get("date", "")
            try:
                dt = datetime.strptime(date_str, "%Y-%m-%d")
                d_name = "Today" if i == 0 else ("Tomorrow" if i == 1 else dt.strftime("%a"))
                d_full = dt.strftime("%A")
                d_date = dt.strftime("%b %d")
            except Exception:
                d_name = f"Day {i+1}"
                d_full = d_name
                d_date = date_str

            hourly = w.get("hourly", [{}])
            mid_h = hourly[len(hourly) // 2] if hourly else {}
            h_desc = mid_h.get("weatherDesc", [{}])[0].get("value", desc)
            h_cat = classify_condition(h_desc)
            t_max_c = str(w.get("maxtempC", temp_c))
            t_min_c = str(w.get("mintempC", temp_c))
            t_max_f = str(w.get("maxtempF", temp_f))
            t_min_f = str(w.get("mintempF", temp_f))
            pop = int(mid_h.get("chanceofrain", "0"))

            forecast_list.append({
                "date": date_str,
                "display_date": d_date,
                "day": d_name,
                "day_full": d_full,
                "temp_max_C": t_max_c,
                "temp_min_C": t_min_c,
                "temp_max_F": t_max_f,
                "temp_min_F": t_min_f,
                "condition": h_desc,
                "weather_category": h_cat,
                "weather_code": str(mid_h.get("weatherCode", "113")),
                "pop": pop,
                "uv": int(w.get("uvIndex", 3)),
            })

        return {
            "configured": True,
            "city": city,
            "country": country,
            "location": location_display,
            "text": summary_text,
            "temp_C": temp_c,
            "temp_F": temp_f,
            "feels_like_C": feels_c,
            "feels_like_F": feels_f,
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
            "forecast_7days": forecast_list,
            "timestamp": time.time()
        }


def make_offline_data(city: str, country: str):
    """Generate structured fallback data when network is unavailable."""
    loc_display = f"{city}, {country}" if (city and country) else (city or country or "Offline")
    days = ["Today", "Tomorrow", "Thu", "Fri", "Sat", "Sun", "Mon"]
    forecast = []
    for i, d in enumerate(days):
        forecast.append({
            "date": "",
            "display_date": "",
            "day": d,
            "day_full": d,
            "temp_max_C": "20",
            "temp_min_C": "12",
            "temp_max_F": "68",
            "temp_min_F": "54",
            "condition": "Partly Cloudy",
            "weather_category": "cloudy",
            "weather_code": "2",
            "pop": 10,
            "uv": 3,
        })

    return {
        "configured": bool(city or country),
        "city": city,
        "country": country,
        "location": loc_display,
        "text": f"20°C • Offline ({loc_display})",
        "temp_C": "20",
        "temp_F": "68",
        "feels_like_C": "20",
        "feels_like_F": "68",
        "condition": "Offline / Cache Unavailable",
        "weather_category": "cloudy",
        "weather_code": "2",
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
        "forecast_7days": forecast,
        "timestamp": time.time()
    }


def fetch_weather(city: str, country: str):
    """Fetch live weather data from Open-Meteo with wttr.in and cache fallback."""
    if not city and not country:
        return make_offline_data("", "")

    try:
        data = fetch_open_meteo(city, country)
        save_weather_cache(data)
        return data
    except Exception as e_om:
        try:
            data = fetch_wttr(city, country)
            save_weather_cache(data)
            return data
        except Exception:
            cached = get_cached_weather(max_age=86400 * 7)
            if cached:
                return cached
            return make_offline_data(city, country)


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
        if cached and cached.get("city") == city and cached.get("country") == country and cached.get("forecast_7days"):
            data = cached

    if not data:
        data = fetch_weather(city, country)

    if as_json:
        print(json.dumps(data))
    else:
        print(data.get("text", "Weather Not Set"))


if __name__ == "__main__":
    main()
