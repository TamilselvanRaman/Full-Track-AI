from typing import Optional, List
from pydantic import BaseModel

# Shared properties
class SessionBase(BaseModel):
    name: Optional[str] = None
    session_type: Optional[str] = None
    bowling_type: Optional[str] = None
    filming_method: Optional[str] = None
    pitch_length: Optional[float] = 22.0

# Properties to receive on creation
class SessionCreate(SessionBase):
    name: str
    session_type: str

# Properties to receive on update
class SessionUpdate(SessionBase):
    pass

# Properties shared by models stored in DB
class SessionInDBBase(SessionBase):
    id: int
    user_id: int

    class Config:
        orm_mode = True

# Properties to return to client
class Session(SessionInDBBase):
    pass
