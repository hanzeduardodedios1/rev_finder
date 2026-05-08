"""
Persist saved comparisons via Supabase REST API (service role).
"""

from __future__ import annotations

import os
import uuid

import requests
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from router import get_current_user

router = APIRouter(tags=["favorites"])


class SavedComparisonBody(BaseModel):
    bike_a_id: str = Field(..., min_length=1)
    bike_b_id: str = Field(..., min_length=1)
    summary: str | None = None


@router.post("/api/favorites/comparison")
async def save_comparison(
    body: SavedComparisonBody,
    user_id: str = Depends(get_current_user),
):
    base_url = os.environ.get("SUPABASE_URL")
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not base_url or not service_key:
        raise HTTPException(
            status_code=500,
            detail="Server misconfiguration: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not set",
        )

    row = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "bike_a_id": body.bike_a_id,
        "bike_b_id": body.bike_b_id,
        "summary": body.summary,
    }

    url = f"{base_url.rstrip('/')}/rest/v1/saved_comparisons"
    headers = {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }

    try:
        resp = requests.post(url, headers=headers, json=row, timeout=20)
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail="Could not reach Supabase",
        ) from exc

    if resp.status_code not in (200, 201):
        print(
            f"Supabase insert failed (server-side only): "
            f"{resp.status_code} {resp.text}",
            flush=True,
        )
        raise HTTPException(status_code=502, detail="Persisting comparison failed")

    return {"ok": True, "id": row["id"]}
