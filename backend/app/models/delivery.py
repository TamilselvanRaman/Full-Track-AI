from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base_class import Base

class Delivery(Base):
    __tablename__ = "deliveries"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("sessions.id"), nullable=False)
    delivery_number = Column(Integer)
    video_filename = Column(String)
    
    # Relationships
    session = relationship("Session", back_populates="deliveries")
    analysis_result = relationship("AnalysisResult", back_populates="delivery", uselist=False, cascade="all, delete-orphan")
