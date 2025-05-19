from sqlalchemy import Column, Integer, String, ForeignKey, Numeric
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, Mapped, mapped_column

Base = declarative_base()

class Projects(Base):
    __tablename__ = 'projects'

    project_id = Column(Integer, primary_key=True)
    project_name = Column(String(100), unique=True, nullable=False)

    input_data = relationship("InputData", back_populates="projects")


class InputData(Base):
    __tablename__ = 'input_data'

    input_id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int] = mapped_column(ForeignKey('projects.project_id'))
    intersection_id: Mapped[int]
    approach = Column(String(1), nullable=False)
    intensity_veh_per_hr: Mapped[int]
    bus_share = Column(Numeric(6, 3), nullable=False)
    len_between_intersections: Mapped[int]
    avg_speed: Mapped[int]

    projects = relationship("Projects", back_populates="input_data")

class OutbutData(Base):
    output_id = Column(Integer, primary_key=True)
    cycle_north_south = Column(Integer, nullable=False)
    green_main_north_south = Column(Integer, nullable=False)
    lost_time_north_south = Column(Integer, nullable=False)
    cycle_east_west = Column(Integer, nullable=False)
    green_main_east_west = Column(Integer, nullable=False)
    lost_time_east_west = Column(Integer, nullable=False)