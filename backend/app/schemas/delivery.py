from typing import Optional
from pydantic import BaseModel

class DeliveryBase(BaseModel):
    session_id: int
    delivery_number: Optional[int] = None
    video_filename: Optional[str] = None

class DeliveryCreate(DeliveryBase):
    session_id: int
    video_filename: str

class DeliveryUpdate(DeliveryBase):
    pass

class DeliveryInDBBase(DeliveryBase):
    id: int

    class Config:
        orm_mode = True

class Delivery(DeliveryInDBBase):
    pass
