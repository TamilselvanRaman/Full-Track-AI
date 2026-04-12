from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
import shutil
import os
import uuid
import tempfile
from typing import Optional

from app import models, schemas
from app.api import deps
from app.db.session import AsyncSessionLocal
from app.services.video_analysis import process_video_and_get_trajectory

router = APIRouter()

TEMP_DIR = os.path.join(tempfile.gettempdir(), "video_uploads")
os.makedirs(TEMP_DIR, exist_ok=True)

# We still return the dictionary to the front end to avoid rewriting the front-end trajectories logic,
# but we store the analytics metadata persistently in Postgres.
# Front-end reads points array from here for now, but metadata comes from DB.
TRAJECTORIES = {}

async def process_video_task(file_path: str, filename: str, delivery_id: int):
    try:
        # Run deep learning extraction
        trajectory = await process_video_and_get_trajectory(file_path)
        TRAJECTORIES[filename] = trajectory
        
        # Save analysis asynchronously safely 
        if "analytics" in trajectory:
            analytics = trajectory["analytics"]
            async with AsyncSessionLocal() as session:
                result = models.AnalysisResult(
                    delivery_id=delivery_id,
                    speed=analytics.get("speed"),
                    line=analytics.get("pitchmap", {}).get("line"),
                    length=analytics.get("pitchmap", {}).get("zone"),
                    swing=analytics.get("swing"),
                    pitchmap_x=analytics.get("pitchmap", {}).get("x"),
                    pitchmap_y=analytics.get("pitchmap", {}).get("y"),
                    release_point_x=analytics.get("release_point", {}).get("x"),
                    release_point_y=analytics.get("release_point", {}).get("y"),
                    run_up_speed=analytics.get("run_up_speed"),
                    biomechanics=analytics.get("biomechanics")
                )
                session.add(result)
                await session.commit()
                
    except Exception as e:
        TRAJECTORIES[filename] = {"error": str(e)}
        print(f"Error processing video task: {e}")
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)

@router.post("/upload")
async def upload_video(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...),
    session_id: Optional[int] = Form(None),
    db: AsyncSession = Depends(deps.get_db)
):
    if not file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="File provided is not a video.")

    file_ext = file.filename.split(".")[-1]
    unique_filename = f"{uuid.uuid4()}.{file_ext}"
    file_path = os.path.join(TEMP_DIR, unique_filename)

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        delivery_id = None
        if session_id:
            # Create a delivery record in the database
            delivery = models.Delivery(
                session_id=session_id,
                video_filename=unique_filename
            )
            db.add(delivery)
            await db.commit()
            await db.refresh(delivery)
            delivery_id = delivery.id
            
        # Add analysis to background task
        background_tasks.add_task(process_video_task, file_path, unique_filename, delivery_id)
        
        return {
            "status": "success",
            "message": "Video upload successful, processing started.",
            "filename": unique_filename,
            "delivery_id": delivery_id
        }
    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/trajectory/{filename}")
async def get_trajectory(filename: str, db: AsyncSession = Depends(deps.get_db)):
    # Serve the in-memory trajectory dictionary (coordinates)
    if filename not in TRAJECTORIES:
        raise HTTPException(status_code=404, detail="Trajectory not found or still processing")
    
    data = TRAJECTORIES[filename]
    if isinstance(data, dict) and "error" in data:
        raise HTTPException(status_code=500, detail=data["error"])
        
    return data
