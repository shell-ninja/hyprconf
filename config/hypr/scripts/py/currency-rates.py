#!/usr/bin/env python3
"""
currency-rates.py — Daily Currency Exchange Rates Service for Hyprconf Omnibar
Fetches and caches daily exchange rates from open exchange rate API with offline fallbacks.
"""

import sys
import os
import json
import time
import urllib.request
import urllib.error

CACHE_DIR = os.path.expanduser("~/.local/share/hyprconf/.cache")
CACHE_FILE = os.path.join(CACHE_DIR, "currency_rates.json")
MAX_CACHE_AGE_SEC = 86400  # 24 hours

# Baseline fallback rates (USD base) to ensure immediate offline operation
FALLBACK_RATES = {
    "USD": 1.0,
    "EUR": 0.924,
    "GBP": 0.772,
    "JPY": 152.3,
    "CAD": 1.391,
    "AUD": 1.518,
    "CHF": 0.867,
    "CNY": 7.125,
    "INR": 84.08,
    "BDT": 119.5,
    "BRL": 5.86,
    "RUB": 97.2,
    "KRW": 1378.0,
    "MXN": 20.25,
    "SGD": 1.321,
    "NZD": 1.674,
    "HKD": 7.773,
    "TRY": 34.35,
    "ZAR": 17.65,
    "AED": 3.672,
    "SAR": 3.753,
    "SEK": 10.68,
    "NOK": 10.98,
    "DKK": 6.89,
    "PLN": 4.02,
    "THB": 33.78,
    "IDR": 15725.0,
    "MYR": 4.375,
    "PHP": 58.35,
    "VND": 25320.0,
    "CZK": 23.35,
    "ILS": 3.74,
    "EGP": 49.02,
    "PKR": 277.8,
    "NGN": 1665.0
}

# Currency Symbols mapping
SYMBOL_TO_CURRENCY = {
    "$": "USD",
    "€": "EUR",
    "£": "GBP",
    "¥": "JPY",
    "₹": "INR",
    "৳": "BDT",
    "₽": "RUB",
    "₩": "KRW",
    "₺": "TRY",
    "฿": "THB",
    "R$": "BRL"
}

def load_cached_rates():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, dict) and "rates" in data:
                    return data
        except Exception:
            pass
    return None

def fetch_online_rates():
    url = "https://open.er-api.com/v6/latest/USD"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Hyprconf-Omnibar/1.0"})
        with urllib.request.urlopen(req, timeout=4) as response:
            if response.status == 200:
                raw = json.loads(response.read().decode("utf-8"))
                if raw.get("result") == "success" and "rates" in raw:
                    cached = {
                        "base": "USD",
                        "timestamp": int(time.time()),
                        "date": raw.get("time_last_update_utc", ""),
                        "rates": raw["rates"]
                    }
                    os.makedirs(CACHE_DIR, exist_ok=True)
                    with open(CACHE_FILE, "w", encoding="utf-8") as f:
                        json.dump(cached, f, indent=2)
                    return cached
    except Exception:
        pass
    return None

def get_rates(force_refresh=False):
    cached = load_cached_rates()
    now = time.time()

    if cached and not force_refresh:
        age = now - cached.get("timestamp", 0)
        if age < MAX_CACHE_AGE_SEC:
            return cached

    # Attempt fetch
    fetched = fetch_online_rates()
    if fetched:
        return fetched

    if cached:
        return cached

    # Fallback default
    default_data = {
        "base": "USD",
        "timestamp": int(now),
        "date": "Offline Default",
        "rates": FALLBACK_RATES
    }
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(default_data, f, indent=2)
    except Exception:
        pass
    return default_data

def convert(amount, from_curr, to_curr):
    from_curr = from_curr.upper().strip()
    to_curr = to_curr.upper().strip()

    rates_data = get_rates()
    rates = rates_data.get("rates", FALLBACK_RATES)

    if from_curr not in rates or to_curr not in rates:
        return {
            "success": False,
            "error": f"Unknown currency code: {from_curr if from_curr not in rates else to_curr}"
        }

    from_rate = rates[from_curr]
    to_rate = rates[to_curr]

    # Convert to USD base first, then to target
    amount_in_usd = float(amount) / from_rate
    target_amount = amount_in_usd * to_rate
    unit_rate = to_rate / from_rate

    # Clean formatting
    def format_num(val):
        if val >= 100:
            return f"{val:,.2f}"
        elif val >= 1:
            return f"{val:,.2f}"
        else:
            return f"{val:,.4f}"

    return {
        "success": True,
        "amount": amount,
        "from": from_curr,
        "to": to_curr,
        "result": target_amount,
        "rate": unit_rate,
        "formatted": f"{format_num(amount)} {from_curr} = {format_num(target_amount)} {to_curr}",
        "rate_str": f"1 {from_curr} = {format_num(unit_rate)} {to_curr}",
        "date": rates_data.get("date", "Today")
    }

def main():
    if len(sys.argv) < 2:
        print(json.dumps(get_rates()))
        return

    arg1 = sys.argv[1]

    if arg1 in ("--fetch", "--refresh"):
        res = fetch_online_rates()
        if res:
            print("Successfully updated currency rates.")
        else:
            print("Failed to fetch rates, using existing or fallback.")
        return

    if arg1 == "--convert" and len(sys.argv) >= 5:
        try:
            amt = float(sys.argv[2])
            f_curr = sys.argv[3]
            t_curr = sys.argv[4]
            res = convert(amt, f_curr, t_curr)
            print(json.dumps(res))
        except ValueError:
            print(json.dumps({"success": False, "error": "Invalid amount"}))
        return

    # Direct query string e.g.: "100 USD to EUR"
    query = " ".join(sys.argv[1:])
    # Normalize query
    q = query.replace(" in ", " to ").replace("=", " to ").replace("->", " to ").strip()
    parts = q.split(" to ")
    if len(parts) == 2:
        left = parts[0].strip()
        target_curr = parts[1].strip()

        # Parse left part e.g. "100 USD" or "$100"
        sym_match = None
        for sym, curr in SYMBOL_TO_CURRENCY.items():
            if left.startswith(sym):
                sym_match = curr
                left = left[len(sym):].strip()
                break

        tokens = left.split()
        if len(tokens) >= 2:
            try:
                amt = float(tokens[0])
                src_curr = tokens[1]
                print(json.dumps(convert(amt, src_curr, target_curr)))
                return
            except Exception:
                pass
        elif len(tokens) == 1 and sym_match:
            try:
                amt = float(tokens[0])
                print(json.dumps(convert(amt, sym_match, target_curr)))
                return
            except Exception:
                pass

    print(json.dumps({"success": False, "error": "Could not parse currency query"}))

if __name__ == "__main__":
    main()
