from typing import Optional
from pydantic import BaseModel

class AnalysisResultBase(BaseModel):
    delivery_id: int
    speed: Optional[float] = None
    line: Optional[str] = None
    length: Optional[str] = None
    swing: Optional[float] = None
    pitchmap_x: Optional[float] = None
    pitchmap_y: Optional[float] = None
    release_point_x: Optional[float] = None
    release_point_y: Optional[float] = None

class AnalysisResultCreate(AnalysisResultBase):
    delivery_id: int

class AnalysisResultUpdate(AnalysisResultBase):
    pass

class AnalysisResultInDBBase(AnalysisResultBase):
    id: int

    class Config:
        orm_mode = True

class AnalysisResult(AnalysisResultInDBBase):
    pass
