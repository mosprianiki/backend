from sqlalchemy import ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.api.project.enums import Approach
from app.core.db import BaseModel


class Projects(BaseModel):
    __tablename__ = "projects"

    project_id: Mapped[int] = mapped_column(primary_key=True)
    project_name: Mapped[str] = mapped_column(String(100), unique=True)

    input_data = relationship(back_populates="projects")
    output_data = relationship(back_populates="projects")


class InputData(BaseModel):
    __tablename__ = "input_data"

    input_id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int] = mapped_column(ForeignKey("projects.project_id"))
    intersection_id: Mapped[int]
    approach: Mapped[Approach]
    intensity_veh_per_hr: Mapped[int]
    bus_share: Mapped[int] = mapped_column(Numeric(6, 3))
    len_between_intersections: Mapped[int]
    avg_speed: Mapped[int]

    projects = relationship(ack_populates="input_data")


class OutputData(BaseModel):
    __tablename__ = "output_data"

    output_id: Mapped[int] = mapped_column(primary_key=True)
    project_id: Mapped[int] = mapped_column(ForeignKey("projects.project_id"))
    cycle_north_south: Mapped[int]
    green_main_north_south: Mapped[int]
    lost_time_north_south: Mapped[int]
    cycle_east_west: Mapped[int]
    green_main_east_west: Mapped[int]
    lost_time_east_west: Mapped[int]

    projects = relationship(back_populates="output_data")
