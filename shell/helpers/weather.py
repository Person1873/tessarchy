#!/usr/bin/env python3
"""Report the current weather for the shell, without any API key.

Location comes from `[Shell] weatherPlace` in `tessarchy/shell.ini`: a city name,
or `auto` (the default) to place the machine by IP. Results are cached under the
state directory so the indicator can still show the last observation offline.
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
IP_URLS = ("https://ipapi.co/json/", "https://ipwho.is/")
CACHE_MAX_AGE = 24 * 3600

CONDITIONS = {
    0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
    45: "Fog", 48: "Rime fog",
    51: "Light drizzle", 53: "Drizzle", 55: "Dense drizzle",
    56: "Freezing drizzle", 57: "Freezing drizzle",
    61: "Light rain", 63: "Rain", 65: "Heavy rain",
    66: "Freezing rain", 67: "Freezing rain",
    71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
    80: "Light showers", 81: "Showers", 82: "Violent showers",
    85: "Snow showers", 86: "Snow showers",
    95: "Thunderstorm", 96: "Thunderstorm with hail", 99: "Thunderstorm with hail",
}


def http_json(url, timeout=8):
    request = urllib.request.Request(url, headers={"User-Agent": "Tessarchy/1.0"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8", "replace"))


def state_path():
    base = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
    return os.path.join(base, "tessarchy", "weather.json")


def read_config(path=None):
    """Return the weather settings from the shell's ini file."""
    if path is None:
        config = os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config")
        path = os.path.join(config, "tessarchy", "shell.ini")
    settings = {"place": "auto", "units": "metric"}
    try:
        with open(path, "r", encoding="utf-8") as handle:
            section = ""
            for line in handle:
                stripped = line.strip()
                if stripped.startswith("[") and stripped.endswith("]"):
                    section = stripped[1:-1].strip()
                elif section == "Shell" and "=" in stripped:
                    key, _, value = stripped.partition("=")
                    key, value = key.strip(), value.strip()
                    if key == "weatherPlace":
                        settings["place"] = value or "auto"
                    elif key == "weatherUnits":
                        settings["units"] = value if value in ("metric", "imperial") else "metric"
    except OSError:
        pass
    return settings


def describe(code, is_day=True):
    """Map a WMO weather code to a description and an icon name."""
    text = CONDITIONS.get(code, "Unknown")
    if code == 0:
        icon = "weather-sun" if is_day else "weather-moon"
    elif code in (1, 2):
        icon = "weather-partly"
    elif code == 3:
        icon = "weather-cloud"
    elif code in (45, 48):
        icon = "weather-fog"
    elif code in (71, 73, 75, 77, 85, 86):
        icon = "weather-snow"
    elif code in (95, 96, 99):
        icon = "weather-storm"
    else:
        icon = "weather-rain"
    return text, icon


def geocode(place, fetch=http_json):
    query = urllib.parse.urlencode({"name": place, "count": 1, "language": "en", "format": "json"})
    results = fetch(GEOCODE_URL + "?" + query).get("results") or []
    if not results:
        raise ValueError("unknown place")
    hit = results[0]
    region = hit.get("admin1") or hit.get("country") or ""
    label = ", ".join(part for part in (hit.get("name"), region) if part)
    return {"latitude": hit["latitude"], "longitude": hit["longitude"], "place": label}


def geolocate(fetch=http_json):
    for url in IP_URLS:
        try:
            data = fetch(url)
        except Exception:
            continue
        latitude, longitude = data.get("latitude"), data.get("longitude")
        if latitude is None or longitude is None:
            continue
        label = ", ".join(part for part in (data.get("city"), data.get("region")) if part)
        return {"latitude": latitude, "longitude": longitude, "place": label or "Current location"}
    raise ValueError("location unknown")


def fetch_weather(location, units, fetch=http_json):
    query = urllib.parse.urlencode({
        "latitude": location["latitude"], "longitude": location["longitude"],
        "current": "temperature_2m,weather_code,is_day",
        "temperature_unit": "fahrenheit" if units == "imperial" else "celsius",
        "timezone": "auto",
    })
    current = fetch(FORECAST_URL + "?" + query)["current"]
    return {
        "temperature": current["temperature_2m"],
        "code": int(current.get("weather_code", 0)),
        "isDay": bool(current.get("is_day", 1)),
    }


def load_cache(path, fetch=http_json):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_cache(path, cache):
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(cache, handle)
    except OSError:
        pass


def summarize(settings, fetch=http_json, cache_file=None, now=None):
    """Return the JSON-ready weather state, falling back to the last cache."""
    now = now or time.time()
    cache_file = cache_file or state_path()
    cache = load_cache(cache_file)
    location = cache.get("location")
    # Re-resolve by name always (the place can change); reuse an auto location for
    # a day so a flaky geolocator does not blank the indicator.
    auto = settings["place"] == "auto"
    try:
        if not auto:
            location = geocode(settings["place"], fetch)
        elif not location or now - location.get("resolved", 0) > CACHE_MAX_AGE:
            location = geolocate(fetch)
    except Exception as error:
        observation = cache.get("observation")
        if auto and observation:
            return dict(observation, ok=True, stale=True, error=str(error) or "location unknown")
        return {"ok": False, "place": "", "error": str(error) or "location unknown"}
    location["resolved"] = now

    units = "°F" if settings["units"] == "imperial" else "°C"
    try:
        current = fetch_weather(location, settings["units"], fetch)
    except Exception as error:
        observation = cache.get("observation")
        if observation:
            return dict(observation, ok=True, stale=True, error=str(error) or "offline",
                        place=location.get("place", ""))
        return {"ok": False, "place": location.get("place", ""), "error": str(error) or "weather unavailable"}
    text, icon = describe(current["code"], current["isDay"])
    result = {
        "ok": True,
        "place": location.get("place", ""),
        "temperature": current["temperature"],
        "unit": units,
        "code": current["code"],
        "description": text,
        "icon": icon,
        "isDay": current["isDay"],
        "updated": time.strftime("%H:%M", time.localtime(now)),
        "stale": False,
        "error": "",
    }
    save_cache(cache_file, {"location": location, "observation": result})
    return result


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    try:
        result = summarize(read_config())
    except Exception as error:  # never fail the shell over weather
        result = {"ok": False, "place": "", "error": str(error) or "weather unavailable"}
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
