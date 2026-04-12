from fastapi import APIRouter

from app.api.v1.endpoints import login, users, ws, video, session

api_router = APIRouter()
api_router.include_router(login.router, tags=["login"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(session.router, prefix="/session", tags=["session"])
api_router.include_router(ws.router, tags=["websocket"])
api_router.include_router(video.router, prefix="/video", tags=["video"])
