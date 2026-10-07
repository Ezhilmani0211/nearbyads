from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from routers.auth import router as auth_router
from routers.shops import router as shops_router
from routers.ads import router as ads_router

app = FastAPI(
    title="NearbyAds Backend",
    version="1.0.0"
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(shops_router)
app.include_router(ads_router)


@app.get("/")
def root():
    return {"message": "NearbyAds Backend is running"}


@app.get("/api/health")
def health():
    return {
        "status": "healthy",
        "service": "NearbyAds Backend"
    }


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError
):
    print("\n========== VALIDATION ERROR ==========")
    print("URL:", request.url)
    print("ERROR:", exc.errors())

    try:
        body = await request.json()
        print("BODY:", body)
    except Exception:
        print("BODY: Could not read JSON")

    print("======================================\n")

    return JSONResponse(
        status_code=422,
        content={
            "detail": exc.errors()
        }
    )