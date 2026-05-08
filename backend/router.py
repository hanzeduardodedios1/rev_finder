import os

import jwt
from dotenv import load_dotenv
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient
from jwt.exceptions import InvalidTokenError, PyJWKClientError
from services.motorcycle_service import fetch_motorcycle_specs

load_dotenv()

router = APIRouter()
_bearer = HTTPBearer(auto_error=False)

SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET")
SUPABASE_URL = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")

_ASYMMETRIC_ALGS = frozenset({"RS256", "RS384", "RS512", "ES256", "ES384", "ES512"})
_jwks_clients: dict[str, PyJWKClient] = {}


def _jwks_client_for_project() -> PyJWKClient:
    if not SUPABASE_URL:
        raise HTTPException(
            status_code=500,
            detail=(
                "Server misconfiguration: SUPABASE_URL is required to verify "
                "asymmetric Supabase JWTs (JWKS)"
            ),
        )
    jwks_url = f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json"
    if jwks_url not in _jwks_clients:
        _jwks_clients[jwks_url] = PyJWKClient(jwks_url)
    return _jwks_clients[jwks_url]


def _decode_supabase_access_token(token: str) -> dict:
    """
    Verify a Supabase Auth access token.

    - Legacy projects: HS256 signed with SUPABASE_JWT_SECRET (dashboard JWT Secret).
    - Signing keys: RS256 / ES256 etc., verified via JWKS on the project URL.
    """
    try:
        header = jwt.get_unverified_header(token)
    except InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token") from None

    alg = header.get("alg") or ""
    audience = "authenticated"

    try:
        if alg == "HS256":
            if not SUPABASE_JWT_SECRET or not str(SUPABASE_JWT_SECRET).strip():
                raise HTTPException(
                    status_code=500,
                    detail=(
                        "Server misconfiguration: SUPABASE_JWT_SECRET is not set "
                        "(required for HS256 tokens)"
                    ),
                )
            return jwt.decode(
                token,
                SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                audience=audience,
            )

        if alg not in _ASYMMETRIC_ALGS:
            raise HTTPException(
                status_code=401,
                detail=f"Unsupported JWT algorithm: {alg or 'missing'}",
            )

        jwks_client = _jwks_client_for_project()
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        return jwt.decode(
            token,
            signing_key.key,
            algorithms=[alg],
            audience=audience,
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired") from None
    except PyJWKClientError:
        raise HTTPException(status_code=401, detail="Invalid token") from None
    except InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token") from None


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> str:
    """
    Extract Bearer JWT, verify via Supabase HS256 secret or JWKS (asymmetric),
    and return the Supabase user id (`sub`).
    """
    if credentials is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    if credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid authentication scheme")

    token = credentials.credentials
    payload = _decode_supabase_access_token(token)

    sub = payload.get("sub")
    if not sub or not isinstance(sub, str):
        raise HTTPException(status_code=401, detail="Invalid token payload")

    return sub


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


@router.post("/api/favorites")
async def add_favorite(user_id: str = Depends(get_current_user)):
    # Example protected route: `user_id` is the verified Supabase UUID from JWT `sub`.
    return {"ok": True, "user_id": user_id, "message": "replace with real favorites logic"}


motorcycle_router = router
