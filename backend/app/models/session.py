from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.db.base_class import Base

class Session(Base):
    __tablename__ = "sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user.id"), nullable=False)
    name = Column(String, index=True)
    session_type = Column(String)  # solo or team
    bowling_type = Column(String)  # bowling or machine
    filming_method = Column(String)  # e.g., tripod
    pitch_length = Column(Float, default=22.0)
    
    # Relationships
    user = relationship("User", back_populates="sessions")
    deliveries = relationship("Delivery", back_populates="session", cascade="all, delete-orphan")
