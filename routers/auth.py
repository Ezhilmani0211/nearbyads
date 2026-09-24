from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from pymongo import MongoClient
import bcrypt
import jwt
import os
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
JWT_SECRET = os.getenv("JWT_SECRET")
JWT_EXPIRES_IN = os.getenv("JWT_EXPIRES_IN", "7d")

client = MongoClient(MONGO_URI)
db = client["nearbyads"]

users_collection = db["users"]

router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"]
)


# =========================
# REGISTER
# =========================

class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: str = "user"


@router.post("/register")
def register(request: RegisterRequest):

    if request.role not in ["user", "shop_owner"]:
        raise HTTPException(
            status_code=400,
            detail="Invalid role"
        )

    existing_user = users_collection.find_one(
        {"email": request.email}
    )

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )

    hashed_password = bcrypt.hashpw(
        request.password.encode("utf-8"),
        bcrypt.gensalt()
    ).decode("utf-8")

    user = {
        "full_name": request.full_name,
        "email": request.email,
        "password": hashed_password,
        "role": request.role,
        "email_verified": False,
        "created_at": datetime.now(timezone.utc)
    }

    result = users_collection.insert_one(user)

    return {
        "message": "Registration successful",
        "user_id": str(result.inserted_id),
        "role": request.role
    }


# =========================
# LOGIN
# =========================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


def create_access_token(user_id, email, role):

    expire = datetime.now(timezone.utc) + timedelta(days=7)

    payload = {
        "user_id": str(user_id),
        "email": email,
        "role": role,
        "exp": expire
    }

    token = jwt.encode(
        payload,
        JWT_SECRET,
        algorithm="HS256"
    )

    return token


@router.post("/login")
def login(request: LoginRequest):

    user = users_collection.find_one(
        {"email": request.email}
    )

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    password_valid = bcrypt.checkpw(
        request.password.encode("utf-8"),
        user["password"].encode("utf-8")
    )

    if not password_valid:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    token = create_access_token(
        user["_id"],
        user["email"],
        user["role"]
    )

    return {
        "message": "Login successful",
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": str(user["_id"]),
            "full_name": user["full_name"],
            "email": user["email"],
            "role": user["role"],
            "email_verified": user.get(
                "email_verified",
                False
            )
        }
    }