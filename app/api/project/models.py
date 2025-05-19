from sqlalchemy import Column, Integer, String, ForeignKey, Numeric
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, Mapped, mapped_column

Base = declarative_base()

class Projects(Base):
    __tablename__ = 'projects'

    project_id = Mapped[int] = mapped_column(primary_key=True)
    project_name = Column(String(100), unique=True, nullable=False)

    input_data = relationship("InputData", back_populates="projects")
    output_data = relationship("OutputData", back_populates="projects")


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
    __tablename__ = 'output_data'

    output_id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int] = mapped_column(ForeignKey('projects.project_id'))
    cycle_north_south: Mapped[int]
    green_main_north_south: Mapped[int]
    lost_time_north_south: Mapped[int]
    cycle_east_west: Mapped[int]
    green_main_east_west: Mapped[int]
    lost_time_east_west: Mapped[int]

    projects = relationship("Projects", back_populates="output_data")