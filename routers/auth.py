from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel, EmailStr
from pymongo import MongoClient
import bcrypt
import jwt
import os
import random
import secrets
import requests

from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv


# =========================================================
# ENVIRONMENT
# =========================================================

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

JWT_SECRET = os.getenv("JWT_SECRET")

JWT_EXPIRES_IN = os.getenv(
    "JWT_EXPIRES_IN",
    "7d"
)


# =========================================================
# EMAIL CONFIGURATION (BREVO API)
# =========================================================

BREVO_API_KEY = os.getenv("BREVO_API_KEY")
SENDER_EMAIL = os.getenv("SENDER_EMAIL")


# =========================================================
# MONGODB
# =========================================================

client = MongoClient(MONGO_URI)

db = client["nearbyads"]

users_collection = db["users"]


# =========================================================
# ROUTER
# =========================================================

router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"]
)


# =========================================================
# DATETIME HELPER
# =========================================================

def ensure_utc(dt):

    if dt is None:
        return None

    if dt.tzinfo is None:
        return dt.replace(
            tzinfo=timezone.utc
        )

    return dt.astimezone(
        timezone.utc
    )


# =========================================================
# VERIFICATION CODE
# =========================================================

def generate_verification_code():

    return str(
        random.randint(
            100000,
            999999
        )
    )


# =========================================================
# SEND EMAIL (BREVO HTTP API - RENDER COMPATIBLE)
# =========================================================

def send_verification_email(
    email,
    verification_code
):

    if not BREVO_API_KEY or not SENDER_EMAIL:
        raise Exception(
            "Brevo email configuration is missing"
        )

    url = "https://api.brevo.com/v3/smtp/email"

    headers = {
        "accept": "application/json",
        "api-key": BREVO_API_KEY,
        "content-type": "application/json"
    }

    body = f"""Hello,

Welcome to NearbyAds!

Your email verification code is:

{verification_code}

This code is valid for 10 minutes.

Please enter this code in the NearbyAds application to verify your email address.

If you did not create a NearbyAds account, please ignore this email.

Regards,
NearbyAds Team"""

    payload = {
        "sender": {
            "name": "NearbyAds",
            "email": SENDER_EMAIL
        },
        "to": [
            {
                "email": email
            }
        ],
        "subject": "NearbyAds - Email Verification Code",
        "textContent": body
    }

    response = requests.post(url, json=payload, headers=headers)

    if response.status_code not in [200, 201]:
        raise Exception(f"Brevo API error: {response.text}")


# =========================================================
# SEND PASSWORD RESET EMAIL (BREVO HTTP API - RENDER COMPATIBLE)
# =========================================================

def send_password_reset_email(
    email,
    reset_code
):

    if not BREVO_API_KEY or not SENDER_EMAIL:
        raise Exception(
            "Brevo email configuration is missing"
        )

    url = "https://api.brevo.com/v3/smtp/email"

    headers = {
        "accept": "application/json",
        "api-key": BREVO_API_KEY,
        "content-type": "application/json"
    }

    body = f"""Hello,

You requested to reset your NearbyAds password.

Your password reset verification code is:

{reset_code}

This code is valid for 10 minutes.

Enter this code in the NearbyAds application to continue resetting your password.

If you did not request a password reset, please ignore this email.

Regards,
NearbyAds Team"""

    payload = {
        "sender": {
            "name": "NearbyAds",
            "email": SENDER_EMAIL
        },
        "to": [
            {
                "email": email
            }
        ],
        "subject": "NearbyAds - Password Reset Code",
        "textContent": body
    }

    response = requests.post(url, json=payload, headers=headers)

    if response.status_code not in [200, 201]:
        raise Exception(f"Brevo API error: {response.text}")


# =========================================================
# REGISTER
# =========================================================

class RegisterRequest(BaseModel):

    full_name: str
    email: EmailStr
    password: str
    role: str = "user"


@router.post("/register")
def register(
    request: RegisterRequest
):

    if request.role not in [
        "user",
        "shop_owner"
    ]:

        raise HTTPException(
            status_code=400,
            detail="Invalid role"
        )

    if len(request.password) < 6:

        raise HTTPException(
            status_code=400,
            detail=(
                "Password must contain "
                "at least 6 characters"
            )
        )

    existing_user = users_collection.find_one(
        {
            "email": request.email
        }
    )

    if existing_user:

        if existing_user.get(
            "email_verified",
            False
        ):

            raise HTTPException(
                status_code=400,
                detail="Email already registered"
            )

        verification_code = (
            generate_verification_code()
        )

        verification_expiry = (
            datetime.now(timezone.utc)
            + timedelta(minutes=10)
        )

        users_collection.update_one(
            {
                "_id":
                    existing_user["_id"]
            },
            {
                "$set": {

                    "verification_code":
                        verification_code,

                    "verification_expires":
                        verification_expiry
                }
            }
        )

        try:

            send_verification_email(
                request.email,
                verification_code
            )

        except Exception as e:

            print(
                "Email sending error:",
                e
            )

            raise HTTPException(
                status_code=500,
                detail=(
                    "Unable to send "
                    "verification email"
                )
            )

        return {

            "message":
                "Verification code sent",

            "user_id":
                str(
                    existing_user["_id"]
                ),

            "role":
                existing_user["role"],

            "requires_verification":
                True
        }

    hashed_password = bcrypt.hashpw(
        request.password.encode("utf-8"),
        bcrypt.gensalt()
    ).decode("utf-8")

    verification_code = (
        generate_verification_code()
    )

    verification_expiry = (
        datetime.now(timezone.utc)
        + timedelta(minutes=10)
    )

    user = {

        "full_name":
            request.full_name,

        "email":
            request.email,

        "password":
            hashed_password,

        "role":
            request.role,

        "email_verified":
            False,

        "verification_code":
            verification_code,

        "verification_expires":
            verification_expiry,

        "created_at":
            datetime.now(timezone.utc)
    }

    result = users_collection.insert_one(
        user
    )

    try:

        send_verification_email(
            request.email,
            verification_code
        )

    except Exception as e:

        print(
            "Email sending error:",
            e
        )

        users_collection.delete_one(
            {
                "_id":
                    result.inserted_id
            }
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to send "
                "verification email"
            )
        )

    return {

        "message":
            "Registration successful. "
            "Verification code sent to your email.",

        "user_id":
            str(
                result.inserted_id
            ),

        "role":
            request.role,

        "requires_verification":
            True
    }


# =========================================================
# VERIFY EMAIL
# =========================================================

class VerifyEmailRequest(BaseModel):

    email: EmailStr
    verification_code: str


@router.post("/verify-email")
def verify_email(
    request: VerifyEmailRequest
):

    user = users_collection.find_one(
        {
            "email": request.email
        }
    )

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User account not found"
        )

    if user.get(
        "email_verified",
        False
    ):

        return {

            "message":
                "Email already verified",

            "email_verified":
                True
        }

    saved_code = user.get(
        "verification_code"
    )

    verification_expiry = user.get(
        "verification_expires"
    )

    if not saved_code:

        raise HTTPException(
            status_code=400,
            detail=(
                "Verification code not found. "
                "Please request a new code."
            )
        )

    if not verification_expiry:

        raise HTTPException(
            status_code=400,
            detail=(
                "Verification code expired. "
                "Please request a new code."
            )
        )

    verification_expiry = ensure_utc(
        verification_expiry
    )

    if (
        datetime.now(timezone.utc)
        > verification_expiry
    ):

        raise HTTPException(
            status_code=400,
            detail=(
                "Verification code expired. "
                "Please request a new code."
            )
        )

    if (
        request.verification_code.strip()
        != str(saved_code).strip()
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid verification code"
        )

    users_collection.update_one(
        {
            "_id":
                user["_id"]
        },
        {
            "$set": {

                "email_verified":
                    True,

                "updated_at":
                    datetime.now(
                        timezone.utc
                    )
            },

            "$unset": {

                "verification_code":
                    "",

                "verification_expires":
                    ""
            }
        }
    )

    return {

        "message":
            "Email verified successfully",

        "email_verified":
            True
    }


# =========================================================
# RESEND VERIFICATION CODE
# =========================================================

class ResendVerificationRequest(BaseModel):

    email: EmailStr


@router.post("/resend-verification")
def resend_verification(
    request: ResendVerificationRequest
):

    user = users_collection.find_one(
        {
            "email":
                request.email
        }
    )

    if not user:

        raise HTTPException(
            status_code=404,
            detail="User account not found"
        )

    if user.get(
        "email_verified",
        False
    ):

        return {

            "message":
                "Email is already verified",

            "email_verified":
                True
        }

    verification_code = (
        generate_verification_code()
    )

    verification_expiry = (
        datetime.now(timezone.utc)
        + timedelta(minutes=10)
    )

    users_collection.update_one(
        {
            "_id":
                user["_id"]
        },
        {
            "$set": {

                "verification_code":
                    verification_code,

                "verification_expires":
                    verification_expiry
            }
        }
    )

    try:

        send_verification_email(
            request.email,
            verification_code
        )

    except Exception as e:

        print(
            "Email sending error:",
            e
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to resend "
                "verification email"
            )
        )

    return {

        "message":
            "New verification code sent",

        "email_verified":
            False
    }


# =========================================================
# LOGIN
# =========================================================

class LoginRequest(BaseModel):

    email: EmailStr
    password: str


# =========================================================
# CREATE ACCESS TOKEN
# =========================================================

def create_access_token(
    user_id,
    email,
    role
):

    expire = (
        datetime.now(timezone.utc)
        + timedelta(days=7)
    )

    payload = {

        "user_id":
            str(user_id),

        "email":
            email,

        "role":
            role,

        "exp":
            expire
    }

    token = jwt.encode(
        payload,
        JWT_SECRET,
        algorithm="HS256"
    )

    return token


# =========================================================
# LOGIN API
# =========================================================

@router.post("/login")
def login(
    request: LoginRequest
):

    user = users_collection.find_one(
        {
            "email":
                request.email
        }
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

    # Admin does not require email verification.
    # User and Shop Owner must verify email first.

    if user.get("role") != "admin" and not user.get(
        "email_verified",
        False
    ):

        raise HTTPException(
            status_code=403,
            detail=(
                "Please verify your email "
                "before logging in"
            )
        )

    token = create_access_token(
        user["_id"],
        user["email"],
        user["role"]
    )

    return {

        "message":
            "Login successful",

        "access_token":
            token,

        "token_type":
            "bearer",

        "user": {

            "id":
                str(
                    user["_id"]
                ),

            "full_name":
                user["full_name"],

            "email":
                user["email"],

            "role":
                user["role"],

            "email_verified":
                user.get(
                    "email_verified",
                    False
                )
        }
    }


# =========================================================
# AUTHENTICATION HELPER
# =========================================================

def get_user_from_token(
    authorization: str
):

    if not authorization:

        raise HTTPException(
            status_code=401,
            detail="Authentication required"
        )

    if not authorization.startswith(
        "Bearer "
    ):

        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token"
        )

    token = authorization.replace(
        "Bearer ",
        "",
        1
    ).strip()

    if not token:

        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token"
        )

    try:

        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=["HS256"]
        )

    except jwt.ExpiredSignatureError:

        raise HTTPException(
            status_code=401,
            detail="Authentication token expired"
        )

    except jwt.InvalidTokenError:

        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token"
        )

    user_id = payload.get(
        "user_id"
    )

    email = payload.get(
        "email"
    )

    if not user_id or not email:

        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token"
        )

    user = users_collection.find_one(
        {
            "email":
                email
        }
    )

    if not user:

        raise HTTPException(
            status_code=401,
            detail="User account not found"
        )

    if str(user["_id"]) != str(user_id):

        raise HTTPException(
            status_code=401,
            detail="Invalid authentication token"
        )

    return user


# =========================================================
# ADMIN - GET ALL USERS
# =========================================================

@router.get("/admin/users")
def get_all_users(
    authorization: str = Header(None)
):

    admin_user = get_user_from_token(
        authorization
    )

    # Only admin can access user management.

    if admin_user.get("role") != "admin":

        raise HTTPException(
            status_code=403,
            detail="Admin access required"
        )

    users = []

    cursor = users_collection.find(
        {},
        {
            "password": 0,
            "verification_code": 0,
            "verification_expires": 0,
            "password_reset_code": 0,
            "password_reset_expires": 0,
            "password_reset_token": 0,
            "password_reset_verified": 0,
        }
    ).sort(
        "created_at",
        -1
    )

    for user in cursor:

        created_at = user.get(
            "created_at"
        )

        users.append({

            "id":
                str(
                    user["_id"]
                ),

            "full_name":
                user.get(
                    "full_name",
                    ""
                ),

            "email":
                user.get(
                    "email",
                    ""
                ),

            "role":
                user.get(
                    "role",
                    "user"
                ),

            "email_verified":
                user.get(
                    "email_verified",
                    False
                ),

            "created_at":
                (
                    created_at.isoformat()
                    if created_at
                    else None
                )
        })

    return {

        "users":
            users,

        "total":
            len(users)
    }


# =========================================================
# CHANGE PASSWORD
# =========================================================

class ChangePasswordRequest(BaseModel):

    email: EmailStr
    new_password: str


@router.put("/change-password")
def change_password(
    request: ChangePasswordRequest,
    authorization: str = Header(None)
):

    user = get_user_from_token(
        authorization
    )

    if user.get("email") != request.email:

        raise HTTPException(
            status_code=403,
            detail=(
                "You can only change "
                "your own password"
            )
        )

    if len(request.new_password) < 6:

        raise HTTPException(
            status_code=400,
            detail=(
                "New password must contain "
                "at least 6 characters"
            )
        )

    new_hashed_password = bcrypt.hashpw(
        request.new_password.encode("utf-8"),
        bcrypt.gensalt()
    ).decode("utf-8")

    users_collection.update_one(
        {
            "_id":
                user["_id"]
        },
        {
            "$set": {

                "password":
                    new_hashed_password,

                "updated_at":
                    datetime.now(
                        timezone.utc
                    )
            }
        }
    )

    return {

        "message":
            "Password changed successfully"
    }


# =========================================================
# FORGOT PASSWORD - SEND RESET CODE
# =========================================================

class ForgotPasswordRequest(BaseModel):

    email: EmailStr


@router.post("/forgot-password")
def forgot_password(
    request: ForgotPasswordRequest
):

    user = users_collection.find_one(
        {
            "email":
                request.email
        }
    )

    if not user:

        return {

            "message":
                "If the email is registered, "
                "a password reset code has been sent."
        }

    reset_code = generate_verification_code()

    reset_expiry = (
        datetime.now(timezone.utc)
        + timedelta(minutes=10)
    )

    reset_token = secrets.token_urlsafe(32)

    users_collection.update_one(
        {
            "_id":
                user["_id"]
        },
        {
            "$set": {

                "password_reset_code":
                    reset_code,

                "password_reset_expires":
                    reset_expiry,

                "password_reset_token":
                    reset_token
            },

            "$unset": {

                "password_reset_verified":
                    ""
            }
        }
    )

    try:

        send_password_reset_email(
            request.email,
            reset_code
        )

    except Exception as e:

        print(
            "Password reset email error:",
            e
        )

        users_collection.update_one(
            {
                "_id":
                    user["_id"]
            },
            {
                "$unset": {

                    "password_reset_code":
                        "",

                    "password_reset_expires":
                        "",

                    "password_reset_token":
                        ""
                }
            }
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to send password "
                "reset email"
            )
        )

    return {

        "message":
            "If the email is registered, "
            "a password reset code has been sent."
    }


# =========================================================
# VERIFY PASSWORD RESET CODE
# =========================================================

class VerifyResetCodeRequest(BaseModel):

    email: EmailStr
    reset_code: str


@router.post("/verify-reset-code")
def verify_reset_code(
    request: VerifyResetCodeRequest
):

    user = users_collection.find_one(
        {
            "email":
                request.email
        }
    )

    if not user:

        raise HTTPException(
            status_code=400,
            detail="Invalid or expired reset code"
        )

    saved_code = user.get(
        "password_reset_code"
    )

    reset_expiry = user.get(
        "password_reset_expires"
    )

    reset_token = user.get(
        "password_reset_token"
    )

    if (
        not saved_code
        or not reset_expiry
        or not reset_token
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid or expired reset code"
        )

    reset_expiry = ensure_utc(
        reset_expiry
    )

    if (
        datetime.now(timezone.utc)
        > reset_expiry
    ):

        users_collection.update_one(
            {
                "_id":
                    user["_id"]
            },
            {
                "$unset": {

                    "password_reset_code":
                        "",

                    "password_reset_expires":
                        "",

                    "password_reset_token":
                        ""
                }
            }
        )

        raise HTTPException(
            status_code=400,
            detail="Reset code expired"
        )

    if (
        request.reset_code.strip()
        != str(saved_code).strip()
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid reset code"
        )

    users_collection.update_one(
        {
            "_id":
                user["_id"]
        },
        {
            "$set": {

                "password_reset_verified":
                    True
            }
        }
    )

    return {

        "message":
            "Reset code verified successfully",

        "reset_token":
            reset_token
    }


# =========================================================
# RESET PASSWORD
# =========================================================

class ResetPasswordRequest(BaseModel):

    email: EmailStr
    reset_token: str
    new_password: str


@router.post("/reset-password")
def reset_password(
    request: ResetPasswordRequest
):

    user = users_collection.find_one(
        {
            "email":
                request.email
        }
    )

    if not user:

        raise HTTPException(
            status_code=400,
            detail="Invalid password reset request"
        )

    if not user.get(
        "password_reset_verified",
        False
    ):

        raise HTTPException(
            status_code=400,
            detail=(
                "Please verify the reset code first"
            )
        )

    saved_token = user.get(
        "password_reset_token"
    )

    if (
        not saved_token
        or request.reset_token != saved_token
    ):

        raise HTTPException(
            status_code=400,
            detail="Invalid password reset request"
        )

    reset_expiry = user.get(
        "password_reset_expires"
    )

    if not reset_expiry:

        raise HTTPException(
            status_code=400,
            detail="Password reset request expired"
        )

    reset_expiry = ensure_utc(
        reset_expiry
    )

    if (
        datetime.now(timezone.utc)
        > reset_expiry
    ):

        raise HTTPException(
            status_code=400,
            detail="Password reset request expired"
        )

    if len(request.new_password) < 6:

        raise HTTPException(
            status_code=400,
            detail=(
                "New password must contain "
                "at least 6 characters"
            )
        )

    new_hashed_password = bcrypt.hashpw(
        request.new_password.encode(
            "utf-8"
        ),
        bcrypt.gensalt()
    ).decode("utf-8")

    users_collection.update_one(
        {
            "_id":
                user["_id"]
        },
        {
            "$set": {

                "password":
                    new_hashed_password,

                "updated_at":
                    datetime.now(
                        timezone.utc
                    )
            },

            "$unset": {

                "password_reset_code":
                    "",

                "password_reset_expires":
                    "",

                "password_reset_token":
                    "",

                "password_reset_verified":
                    ""
            }
        }
    )

    return {

        "message":
            "Password reset successfully"
    }