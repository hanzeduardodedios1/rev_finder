import os

from dotenv import load_dotenv

load_dotenv()

from fastapi import Depends, FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

from router import get_current_user, motorcycle_router
from routers.comparison_router import router as comparison_router
from routers.favorites_router import router as favorites_router

_raw_origins = os.getenv("CORS_ALLOW_ORIGINS", "")
CORS_ALLOW_ORIGINS = [
    o.strip().rstrip("/")
    for part in _raw_origins.split(",")
    if (o := part.strip())
]
if not CORS_ALLOW_ORIGINS:
    raise RuntimeError(
        "CORS_ALLOW_ORIGINS is empty or unset; set comma-separated browser origins."
    )

app = FastAPI()


@app.on_event("startup")
async def _verify_gemini_api_key_loaded() -> None:
    key = os.getenv("GEMINI_API_KEY")
    if key is None or not str(key).strip():
        raise RuntimeError("GEMINI_API_KEY is missing or empty")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOW_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(motorcycle_router)
app.include_router(comparison_router)
app.include_router(favorites_router)


class Item(BaseModel):
    name: str
    price: float
    is_offer: bool | None = None


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.get("/items/{item_id}")
def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}


@app.put("/items/{item_id}")
def update_item(
    item_id: int,
    item: Item,
    user_id: str = Depends(get_current_user),
):
    return {"item_name": item.name, "item_id": item_id}
