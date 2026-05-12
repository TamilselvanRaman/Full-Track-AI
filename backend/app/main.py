from contextlib import asynccontextmanager
from sqlalchemy.future import select
from app.db.base import Base
from app.db.session import engine, AsyncSessionLocal
from app.models.user import User
from app.core import security

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create default user if it doesn't exist
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(User).where(User.id == 1))
        user = result.scalars().first()
        if not user:
            user = User(
                id=1,
                email="guest@example.com",
                hashed_password=security.get_password_hash("guest123"),
                full_name="Guest User",
                is_active=True,
                is_superuser=True,
            )
            db.add(user)
            await db.commit()
    yield

app = FastAPI(
    title=settings.PROJECT_NAME, 
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# Set all CORS enabled origins
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

@app.get("/")
async def root():
    return {"message": "Welcome to Full-Track AI System API"}

@app.get("/health")
async def health_check():
    return {"status": "ok"}

from app.api.v1.api import api_router
app.include_router(api_router, prefix=settings.API_V1_STR)
