from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
import os
from dotenv import load_dotenv

load_dotenv()

JWT_SECRET = os.getenv("JWT_SECRET")

security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials =
        Depends(security)
):
    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=["HS256"]
        )

        return payload

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=401,
            detail="Token expired"
        )

    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=401,
            detail="Invalid token"
        )


def require_role(required_role: str):

    def role_checker(
        current_user=Depends(get_current_user)
    ):
        if current_user.get("role") != required_role:
            raise HTTPException(
                status_code=403,
                detail="Access denied"
            )

        return current_user

    return role_checker