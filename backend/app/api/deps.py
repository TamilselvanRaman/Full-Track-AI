from typing import Generator, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from pydantic import ValidationError
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User
from app.schemas import TokenPayload
from app.core import security
from app.core.config import settings
from app.db.session import get_db
from sqlalchemy.future import select

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/login/access-token",
    auto_error=False
)

async def get_current_user(
    token: Optional[str] = Depends(reusable_oauth2),
    db: AsyncSession = Depends(get_db),
) -> User:
    if not token:
        # Fallback to default user for "no-login" mode
        result = await db.execute(select(User).where(User.id == 1))
        user = result.scalars().first()
        if not user:
            # If default user doesn't exist, we still need to allow the app to proceed 
            # if we want a true bypass, but most endpoints need a user_id.
            # We'll handle creation of this user in main.py startup.
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Not authenticated and no default user found",
            )
        return user

    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[security.ALGORITHM]
        )
        token_data = TokenPayload(**payload)
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )
    
    result = await db.execute(select(User).where(User.id == token_data.sub))
    user = result.scalars().first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return user

def get_current_active_superuser(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=400, detail="The user doesn't have enough privileges"
        )
    return current_user
