import asyncio
import sys
import os

# Add the current directory to sys.path so we can import app
sys.path.append(os.getcwd())

from app.db.session import SessionLocal
from app import models
from app.core.security import get_password_hash
from sqlalchemy.future import select

async def create_default_user():
    print("Creating default user...")
    async with SessionLocal() as db:
        # Check if user exists
        stmt = select(models.User).where(models.User.email == "admin@example.com")
        result = await db.execute(stmt)
        user = result.scalars().first()
        
        if user:
            print("User admin@example.com already exists.")
            return

        # Create user
        new_user = models.User(
            email="admin@example.com",
            hashed_password=get_password_hash("password123"),
            full_name="Admin User",
            is_active=True,
            is_superuser=True,
        )
        db.add(new_user)
        await db.commit()
        print("User admin@example.com created successfully.")
        print("Password: password123")

if __name__ == "__main__":
    if sys.platform == 'win32':
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(create_default_user())
