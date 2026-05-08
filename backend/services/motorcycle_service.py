# services/motorcycle_service.py
#
# This service:
# 1. Calls the Motorcycle Ninjas API.
# 2. Parses the raw API JSON into clear frontend-ready values.
# 3. Converts units correctly.
# 4. Creates a MotorcycleSpecs object.
# 5. Returns enriched JSON to Flutter.
#
# The backend owns parsing and score calculation.
# Flutter should only display the clean JSON returned by this service.

import os
import re
from pathlib import Path

import requests
from dotenv import load_dotenv

from classes import MotorcycleSpecs


current_file = Path(__file__).resolve()
env_path = current_file.parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

API_KEY = os.getenv("MOTORCYCLE_API_KEY")

if not API_KEY:
    raise ValueError("No API Key found.")

headers = {
    "X-Api-Key": API_KEY,
}


MAKE_ALIASES = {
    "kawasaki": "kawasaki",
    "yamaha": "yamaha",
    "honda": "honda",
    "suzuki": "suzuki",
    "ducati": "ducati",
    "bmw": "bmw",
    "aprilia": "aprilia",
    "triumph": "triumph",
    "ktm": "ktm",
    "harley": "harley-davidson",
    "harley davidson": "harley-davidson",
    "harley-davidson": "harley-davidson",
    "indian": "indian",
    "royal enfield": "royal enfield",
    "husqvarna": "husqvarna",
    "mv agusta": "mv agusta",
    "moto guzzi": "moto guzzi",
}


def _clean_text(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9\- ]+", " ", value.lower())
    return re.sub(r"\s+", " ", cleaned).strip()


def _canonicalize_make(value: str) -> str:
    normalized = _clean_text(value)

    if not normalized:
        return ""

    if normalized in MAKE_ALIASES:
        return MAKE_ALIASES[normalized]

    space_normalized = normalized.replace("-", " ")

    return MAKE_ALIASES.get(space_normalized, "")


def _extract_make_and_model_from_query(query: str):
    normalized_query = _clean_text(query)

    if not normalized_query:
        return "", ""

    tokens = normalized_query.split()
    detected_make = ""
    model_tokens = tokens[:]

    for span_size in (3, 2, 1):
        found = False

        for i in range(0, len(tokens) - span_size + 1):
            span = " ".join(tokens[i : i + span_size])
            canonical_make = _canonicalize_make(span)

            if canonical_make:
                detected_make = canonical_make
                model_tokens = tokens[:i] + tokens[i + span_size :]
                found = True
                break

        if found:
            break

    detected_model = " ".join(model_tokens).strip()

    return detected_make, detected_model


def _get_first_value(record: dict, keys: list[str]):
    for key in keys:
        value = record.get(key)

        if value is None:
            continue

        if isinstance(value, str) and value.strip().lower() in ("", "null", "none", "n/a"):
            continue

        return value

    return None


def _parse_string(record: dict, keys: list[str]):
    value = _get_first_value(record, keys)

    if value is None:
        return None

    return str(value).strip()


def _first_number(value):
    if value is None:
        return None

    if isinstance(value, (int, float)):
        return float(value)

    match = re.search(r"[-+]?\d*\.?\d+", str(value))

    if not match:
        return None

    return float(match.group(0))


def _parse_int(record: dict, keys: list[str]):
    value = _get_first_value(record, keys)

    if value is None:
        return None

    if isinstance(value, int):
        return value

    match = re.search(r"\d+", str(value))

    if not match:
        return None

    return int(match.group(0))


def _parse_engine_cc(record: dict):
    value = _get_first_value(
        record,
        ["engine_cc", "engineCC", "engine cc", "displacement"],
    )

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return float(value)

    text = str(value).lower()

    cc_match = re.search(r"(\d+(?:\.\d+)?)\s*(?:ccm|cc)\b", text)

    if cc_match:
        return round(float(cc_match.group(1)), 2)

    return _first_number(value)


def _parse_horsepower(record: dict):
    value = _get_first_value(
        record,
        ["horsepower", "power", "max_power", "hp"],
    )

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return float(value)

    text = str(value).lower()

    hp_match = re.search(r"(\d+(?:\.\d+)?)\s*hp\b", text)

    if hp_match:
        return round(float(hp_match.group(1)), 2)

    return _first_number(value)


def _parse_torque_lb_ft(record: dict):
    value = _get_first_value(record, ["torque", "max_torque"])

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return float(value)

    text = str(value).lower()

    ft_lbs_match = re.search(
        r"(\d+(?:\.\d+)?)\s*ft\.?\s*-?\s*lbs?",
        text,
    )

    if ft_lbs_match:
        return round(float(ft_lbs_match.group(1)), 2)

    nm_match = re.search(r"(\d+(?:\.\d+)?)\s*nm\b", text)

    if nm_match:
        nm = float(nm_match.group(1))
        return round(nm * 0.737562, 2)

    return _first_number(value)


def _parse_weight_lb(record: dict):
    value = _get_first_value(
        record,
        ["total_weight", "wet_weight", "dry_weight", "weight"],
    )

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return float(value)

    text = str(value).lower()

    pounds_match = re.search(r"(\d+(?:\.\d+)?)\s*pounds?", text)

    if pounds_match:
        return round(float(pounds_match.group(1)), 2)

    kg_match = re.search(r"(\d+(?:\.\d+)?)\s*kg\b", text)

    if kg_match:
        kg = float(kg_match.group(1))
        return round(kg * 2.20462, 2)

    return _first_number(value)


def _parse_seat_height_in(record: dict):
    value = _get_first_value(
        record,
        ["seat_height", "seatHeight", "seat height"],
    )

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return float(value)

    text = str(value).lower()

    inches_match = re.search(r"(\d+(?:\.\d+)?)\s*inches?", text)

    if inches_match:
        return round(float(inches_match.group(1)), 2)

    mm_match = re.search(r"(\d+(?:\.\d+)?)\s*mm\b", text)

    if mm_match:
        mm = float(mm_match.group(1))
        return round(mm / 25.4, 2)

    return _first_number(value)


def _parse_fuel_capacity_gal(record: dict):
    value = _get_first_value(
        record,
        ["fuel_capacity", "fuelCapacity", "fuel capacity", "fuel_tank_capacity"],
    )

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return round(float(value) * 0.264172, 2)

    text = str(value).lower()

    gallons_match = re.search(
        r"(\d+(?:\.\d+)?)\s*(?:us\s*)?gallons?",
        text,
    )

    if gallons_match:
        return round(float(gallons_match.group(1)), 2)

    litres_match = re.search(
        r"(\d+(?:\.\d+)?)\s*(?:litres?|liters?|l)\b",
        text,
    )

    if litres_match:
        litres = float(litres_match.group(1))
        return round(litres * 0.264172, 2)

    return _first_number(value)


def _parse_fuel_capacity_liters(record: dict):
    value = _get_first_value(
        record,
        ["fuel_capacity", "fuelCapacity", "fuel capacity", "fuel_tank_capacity"],
    )

    if value is None:
        return None

    if isinstance(value, (int, float)):
        return float(value)

    text = str(value).lower()

    litres_match = re.search(
        r"(\d+(?:\.\d+)?)\s*(?:litres?|liters?|l)\b",
        text,
    )

    if litres_match:
        return round(float(litres_match.group(1)), 2)

    return _first_number(value)


def _parse_mpg(record: dict):
    direct = _get_first_value(record, ["mpg", "fuel_economy", "fuel economy"])

    if direct is not None:
        return _first_number(direct)

    value = _get_first_value(record, ["fuel_consumption", "fuelConsumption"])

    if value is None:
        return None

    text = str(value).lower()

    mpg_match = re.search(r"(\d+(?:\.\d+)?)\s*mpg\b", text)

    if mpg_match:
        return round(float(mpg_match.group(1)), 2)

    return None


def _infer_cylinders_from_engine(record: dict):
    engine = _parse_string(record, ["engine", "engine_type", "engineType"])

    if engine is None:
        return None

    text = engine.lower()

    if "single" in text or "one-cylinder" in text or "1-cylinder" in text:
        return 1

    if "parallel twin" in text or "v-twin" in text or "twin" in text or "two-cylinder" in text or "2-cylinder" in text:
        return 2

    if "triple" in text or "three-cylinder" in text or "3-cylinder" in text:
        return 3

    if (
        "inline four" in text
        or "in-line four" in text
        or "four-cylinder" in text
        or "4-cylinder" in text
        or "four cylinder" in text
    ):
        return 4

    if "six-cylinder" in text or "6-cylinder" in text or "six cylinder" in text:
        return 6

    return None


def _build_specs_from_api_record(record: dict) -> MotorcycleSpecs:
    return MotorcycleSpecs(
        engineCC=_parse_engine_cc(record),
        seatHeightIn=_parse_seat_height_in(record),
        engineType=_parse_string(record, ["engine", "engine_type", "engineType"]),
        cylinders=(
            _parse_int(record, ["cylinders", "cylinder", "number_of_cylinders"])
            or _infer_cylinders_from_engine(record)
        ),
        horsepower=_parse_horsepower(record),
        torqueLbFt=_parse_torque_lb_ft(record),
        weightLb=_parse_weight_lb(record),
        fuelCapacityGal=_parse_fuel_capacity_gal(record),
        mpg=_parse_mpg(record),
        coolingSystem=_parse_string(record, ["cooling", "cooling_system", "coolingSystem"]),
        gearbox=_parse_int(record, ["gearbox", "gears"]),
        clutchType=_parse_string(record, ["clutch", "clutch_type", "clutchType"]),
        frame=_parse_string(record, ["frame"]),
        frontBrakeType=_parse_string(record, ["front_brakes", "front_brake_type", "frontBrakeType"]),
        rearBrakeType=_parse_string(record, ["rear_brakes", "rear_brake_type", "rearBrakeType"]),
        frontSuspension=_parse_string(record, ["front_suspension", "frontSuspension"]),
        rearSuspension=_parse_string(record, ["rear_suspension", "rearSuspension"]),
        topSpeedMph=_first_number(_get_first_value(record, ["top_speed", "topSpeed", "top speed"])),
    )


def _enrich_motorcycle_record(record: dict) -> dict:
    """
    Return clear frontend-ready JSON for one motorcycle.

    The raw API record is parsed into a MotorcycleSpecs object.
    MotorcycleSpecs.to_dict() returns:
    - parsed numeric fields
    - normalized text fields
    - calculated fields such as power_score and comfort_score
    """
    specs = _build_specs_from_api_record(record)
    parsed_and_calculated = specs.to_dict()

    enriched_record = {
        # Basic identity.
        "make": record.get("make"),
        "model": record.get("model"),
        "year": record.get("year"),
        "type": record.get("type"),

        # Human-readable display fields for cards/main specs.
        "engine": _parse_string(record, ["engine", "displacement"]),
        "power": _parse_string(record, ["power", "horsepower", "max_power", "hp"]),
        "torque_display": _parse_string(record, ["torque", "max_torque"]),
        "weight_display": _parse_string(
            record,
            ["total_weight", "wet_weight", "dry_weight", "weight"],
        ),
        "seat_height_display": _parse_string(
            record,
            ["seat_height", "seatHeight", "seat height"],
        ),
        "transmission": _parse_string(record, ["transmission", "gearbox"]),

        # Raw fields preserved in case the frontend ever needs to display them.
        "raw_displacement": record.get("displacement"),
        "raw_engine": record.get("engine"),
        "raw_power": record.get("power"),
        "raw_torque": record.get("torque"),
        "raw_total_weight": record.get("total_weight"),
        "raw_seat_height": record.get("seat_height"),
        "raw_fuel_capacity": record.get("fuel_capacity"),
        "raw_fuel_consumption": record.get("fuel_consumption"),

        # Parsed values and calculated scores from MotorcycleSpecs.
        **parsed_and_calculated,

        # Fuel conversion context.
        "fuel_capacity_original": _parse_fuel_capacity_liters(record),
        "fuel_capacity_original_unit": "L",
        "fuel_capacity_unit": "gal",
    }

    return enriched_record


def _enrich_motorcycle_records(raw_data):
    if isinstance(raw_data, list):
        return [
            _enrich_motorcycle_record(record)
            for record in raw_data
            if isinstance(record, dict)
        ]

    if isinstance(raw_data, dict):
        return _enrich_motorcycle_record(raw_data)

    return raw_data


def fetch_motorcycle_specs(make: str = "", model: str = ""):
    url = "https://api.api-ninjas.com/v1/motorcycles"
    query_params = {}

    explicit_make = make.strip()
    explicit_model = model.strip()

    combined_query = " ".join(part for part in [explicit_make, explicit_model] if part).strip()

    parsed_make, parsed_model = _extract_make_and_model_from_query(combined_query)

    canonical_explicit_make = _canonicalize_make(explicit_make)

    final_make = canonical_explicit_make or parsed_make
    final_model = explicit_model if explicit_model else parsed_model

    if final_make and final_model:
        _, remaining_model = _extract_make_and_model_from_query(final_model)

        if remaining_model:
            final_model = remaining_model

    if final_make:
        query_params["make"] = final_make

    if final_model:
        query_params["model"] = final_model
    elif not query_params and combined_query:
        query_params["model"] = combined_query

    try:
        print(f"--- SEARCHING API NINJAS FOR: {final_model or model or combined_query} ---")
        response = requests.get(
            url,
            headers=headers,
            params=query_params,
            timeout=15,
        )
        print(f"API NINJAS STATUS: {response.status_code}")
        response.raise_for_status()

        raw_data = response.json()
        print(f"FOUND {len(raw_data) if isinstance(raw_data, list) else 1} BIKES")

        if not raw_data and combined_query:
            print(f"--- SEARCHING API NINJAS FOR: {combined_query} ---")
            fallback_response = requests.get(
                url,
                headers=headers,
                params={"model": combined_query},
                timeout=15,
            )
            print(f"API NINJAS STATUS: {fallback_response.status_code}")
            fallback_response.raise_for_status()
            raw_data = fallback_response.json()
            print(f"FOUND {len(raw_data) if isinstance(raw_data, list) else 1} BIKES")

        return _enrich_motorcycle_records(raw_data)

    except requests.exceptions.RequestException as e:
        print(f"Ninjas Motorcycles API failed: {e}")
        if "response" in locals() and response is not None:
            print(response.text)
        elif "fallback_response" in locals() and fallback_response is not None:
            print(fallback_response.text)
        return {"error": "Failed to fetch data from external API"}