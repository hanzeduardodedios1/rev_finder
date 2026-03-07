# Endpoints to handle JSON from APIs

from fastapi import APIRouter, HTTPException
from services.motorcycle_service import fetch_motorcycle_specs

router = APIRouter()

@router.get("/api/motorcycles/search")
async def search_motorcycles(make: str = "", model: str = ""):
    data = fetch_motorcycle_specs(make = make, model = model)

    # checks whether our request failed, if it fails raise a client-side error 
    if isinstance(data, dict) and "error" in data:
        raise HTTPException(status_code=400, detail=data["error"])
    
    motorcycle_model_data = []
    for motorcycles in data:
        motorcycle_model_data.append({
            "make": motorcycles.get("make"),
            "model": motorcycles.get("model"),
            "year": motorcycles.get("year")
        })
    
    return motorcycle_model_data

@router.get("/api/motorcycles/specs")
async def get_motorcycle_specs(make: str = "", model: str = ""):
    data = fetch_motorcycle_specs(make=make, model=model)

    if isinstance(data, dict) and "error" in data:
        raise HTTPException(status_code=400, detail=data["error"])
    
    return data