from sqlalchemy import Column, Integer, String, Float, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.db.base_class import Base

class AnalysisResult(Base):
    __tablename__ = "analysis_results"
    
    id = Column(Integer, primary_key=True, index=True)
    delivery_id = Column(Integer, ForeignKey("deliveries.id"), nullable=False, unique=True)
    
    # Analytics metrics
    speed = Column(Float)
    line = Column(String)
    length = Column(String)
    swing = Column(Float)
    run_up_speed = Column(Float)
    biomechanics = Column(JSON)
    
    # Coordinates
    pitchmap_x = Column(Float)
    pitchmap_y = Column(Float)
    release_point_x = Column(Float)
    release_point_y = Column(Float)
    
    # Relationships
    delivery = relationship("Delivery", back_populates="analysis_result")
