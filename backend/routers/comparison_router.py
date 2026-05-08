"""
Comparison endpoints (AI summary).
"""

from __future__ import annotations

import json
import os
import time
import traceback
from collections import defaultdict
from threading import Lock

import google.generativeai as genai
from fastapi import APIRouter, Depends, HTTPException
from google.api_core.exceptions import GoogleAPIError
from google.generativeai.types import BlockedPromptException
from pydantic import BaseModel, Field

from router import get_current_user

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

router = APIRouter(tags=["comparison"])

_limits: dict[tuple[str, str], list[float]] = defaultdict(list)
_rate_lock = Lock()

# v1beta no longer serves legacy IDs like gemini-1.5-flash; override via GEMINI_MODEL if needed.
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

SYSTEM_PROMPT = (
    "You are a motorcycle buying advisor. Given two bikes and their computed "
    "specs scores, write a 2–3 sentence plain-English verdict to help a buyer "
    "decide. Be direct. Mention the use case each bike suits best. No markdown, "
    "no bullet points, plain prose only."
)


def _rate_limit_buckets(user_id: str, *, max_calls: int = 10, window_sec: float = 60.0) -> None:
    bucket_key = ("comparison_summary", user_id)
    now = time.monotonic()
    with _rate_lock:
        window_start = now - window_sec
        dq = _limits[bucket_key]
        while dq and dq[0] < window_start:
            dq.pop(0)
        if len(dq) >= max_calls:
            raise HTTPException(status_code=429, detail="Too many requests; try later")
        dq.append(now)


class ComparisonSummaryRequest(BaseModel):
    bike_a: dict = Field(default_factory=dict)
    bike_b: dict = Field(default_factory=dict)
    scores: dict = Field(default_factory=dict)


@router.post("/api/comparison/summary")
async def comparison_summary(
    body: ComparisonSummaryRequest,
    user_id: str = Depends(get_current_user),
):
    _rate_limit_buckets(user_id)

    payload = {
        "bike_a": body.bike_a,
        "bike_b": body.bike_b,
        "scores": body.scores,
    }
    user_content = json.dumps(payload)

    model = genai.GenerativeModel(
        GEMINI_MODEL,
        system_instruction=SYSTEM_PROMPT,
    )

    try:
        response = await model.generate_content_async(user_content)
    except GoogleAPIError as e:
        print(
            f"Gemini GoogleAPIError (operators): {type(e).__name__}: {e!r}",
            flush=True,
        )
        traceback.print_exc()
        raise HTTPException(
            status_code=502,
            detail="Upstream AI provider error",
        ) from None
    except BlockedPromptException as e:
        print(
            f"Gemini BlockedPromptException (operators): {type(e).__name__}: {e!r}",
            flush=True,
        )
        traceback.print_exc()
        raise HTTPException(
            status_code=400,
            detail="Request blocked by safety filters",
        ) from None
    except Exception as e:
        print(
            f"Gemini unexpected exception (operators): {type(e).__name__}: {e!r}",
            flush=True,
        )
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail="Comparison summary failed",
        ) from None

    try:
        summary = response.text.strip()
    except ValueError:
        summary = ""

    if not summary:
        print("Gemini returned empty summary text", flush=True)
        raise HTTPException(status_code=502, detail="Empty response from AI model")

    return {"summary": summary}
