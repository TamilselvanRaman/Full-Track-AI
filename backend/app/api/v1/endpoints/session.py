from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.future import select
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession

from app import models, schemas
from app.api import deps

router = APIRouter()

@router.post("/create", response_model=schemas.Session)
async def create_session(
    *,
    db: AsyncSession = Depends(deps.get_db),
    session_in: schemas.SessionCreate,
    current_user: models.User = Depends(deps.get_current_user),
) -> Any:
    """
    Create new session.
    """
    session = models.Session(
        **session_in.dict(),
        user_id=current_user.id,
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session

@router.get("/mine", response_model=List[schemas.Session])
async def get_my_sessions(
    *,
    db: AsyncSession = Depends(deps.get_db),
    current_user: models.User = Depends(deps.get_current_user),
) -> Any:
    """
    Get all sessions for the current user.
    """
    result = await db.execute(
        select(models.Session)
        .where(models.Session.user_id == current_user.id)
        .order_by(models.Session.id.desc())
    )
    return result.scalars().all()

@router.get("/{session_id}", response_model=schemas.Session)
async def get_session(
    *,
    db: AsyncSession = Depends(deps.get_db),
    session_id: int,
    current_user: models.User = Depends(deps.get_current_user),
) -> Any:
    """
    Get session by ID.
    """
    result = await db.execute(select(models.Session).where(models.Session.id == session_id))
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    return session

@router.post("/close", response_model=schemas.Session)
async def close_session(
    *,
    db: AsyncSession = Depends(deps.get_db),
    session_id: int,
    current_user: models.User = Depends(deps.get_current_user),
) -> Any:
    """
    Close session (marks it as done/archived, currently just returns it).
    """
    result = await db.execute(select(models.Session).where(models.Session.id == session_id))
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    
    # Normally you'd add an "is_active" or "closed_at" field to Session model.
    # For MVP we just return it.
    return session

@router.delete("/{session_id}", response_model=schemas.Session)
async def delete_session(
    *,
    db: AsyncSession = Depends(deps.get_db),
    session_id: int,
    current_user: models.User = Depends(deps.get_current_user),
) -> Any:
    """
    Delete a session.
    """
    result = await db.execute(select(models.Session).where(models.Session.id == session_id))
    session = result.scalars().first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    if session.user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=400, detail="Not enough permissions")
    
    await db.delete(session)
    await db.commit()
    return session
