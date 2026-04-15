import os
import requests
import re
from dotenv import load_dotenv
from pathlib import Path


current_file = Path(__file__).resolve()
env_path = current_file.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)

# Safely get API key from .env file
API_KEY = os.getenv("MOTORCYCLE_API_KEY")

# Safety check to ensure API key is present
if not API_KEY:
    raise ValueError("No API Key found.")

headers = {
    "X-Api-Key": API_KEY
} #"X-Api-Key" is the specific header for Motorcycles API from Ninjas

KNOWN_MAKES = [
    "kawasaki",
    "yamaha",
    "honda",
    "suzuki",
    "ducati",
    "bmw",
    "aprilia",
    "triumph",
    "ktm",
    "harley-davidson",
]

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
    # Fallback: allow values like "HARLEY DAVIDSON" or "harley    davidson"
    space_normalized = normalized.replace("-", " ")
    return MAKE_ALIASES.get(space_normalized, "")


def _extract_make_and_model_from_query(query: str):
    normalized_query = _clean_text(query)
    if not normalized_query:
        return "", ""

    tokens = normalized_query.split()
    detected_make = ""
    model_tokens = tokens[:]

    # Search will prefer longest match
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

    # Remove duplication of make in model text
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
        response = requests.get(url, headers=headers, params=query_params, timeout=15)
        response.raise_for_status()
        raw_data = response.json()

        # Some searches are broader when passed as a model
        if not raw_data and combined_query:
            fallback_response = requests.get(
                url, headers=headers, params={"model": combined_query}, timeout=15
            )
            fallback_response.raise_for_status()
            raw_data = fallback_response.json()

        # If the search is for a make only, try with no params
        if not raw_data and final_make and not final_model:
            broad_response = requests.get(url, headers=headers, timeout=15)
            broad_response.raise_for_status()
            raw_data = broad_response.json()

        return raw_data

    except requests.exceptions.RequestException as e:
        print(f"Ninjas Motorcycles API failed: {e}")
        return {"error": "Failed to fetch data from external API"}