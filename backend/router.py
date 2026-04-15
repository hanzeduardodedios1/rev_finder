from fastapi import APIRouter, HTTPException
from services.motorcycle_service import fetch_motorcycle_specs

router = APIRouter()

def _fetch_or_raise(make: str, model: str):
    data = fetch_motorcycle_specs(make=make, model=model)

    if isinstance(data, dict) and "error" in data:
        raise HTTPException(status_code=400, detail=data["error"])

    # Return API response
    return data

@router.get("/api/motorcycles/search")
async def search_motorcycles(make: str = "", model: str = ""):
    return _fetch_or_raise(make=make, model=model)

@router.get("/api/motorcycles/specs")
async def get_motorcycle_specs(make: str = "", model: str = ""):
    return _fetch_or_raise(make=make, model=model)