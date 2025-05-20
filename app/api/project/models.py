from sqlalchemy import ForeignKey, Numeric, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.api.project.enums import Approach
from app.core.config import StaticConfig
from app.core.db import BaseModel


class Projects(BaseModel):
    __tablename__ = "projects"

    project_id: Mapped[int] = mapped_column(primary_key=True)
    project_name: Mapped[str] = mapped_column(
        String(StaticConfig.NAME_STR_LENGTH),
        unique=True,
    )

    intersections = relationship(back_populates="projects")


class Intersection(BaseModel):
    __tablename__ = "intersections"
    __table_args__ = (
        UniqueConstraint(
            "id",
            "project_id",
            name="intersection_project_uc",
        ),
    )

    id: Mapped[int]
    project_id: Mapped[int] = mapped_column(ForeignKey("projects.project_id"))


class FlowsInputData(BaseModel):
    __tablename__ = "input_data"

    id: Mapped[int] = mapped_column(primary_key=True)
    intersection_id: Mapped[int] = mapped_column(ForeignKey("intersections.id"))
    approach: Mapped[Approach]
    intensity_veh_per_hr: Mapped[int]
    bus_share: Mapped[int] = mapped_column(Numeric(6, 3))
    len_between_intersections: Mapped[int]
    avg_speed: Mapped[int]


class RelationsInputData(BaseModel):
    __tablename__ = "relation_input_data"

    id: Mapped[int] = mapped_column(primary_key=True)
    first_intersection_id: Mapped[int] = mapped_column(ForeignKey("intersections.id"))
    second_intersection_id: Mapped[int] = mapped_column(ForeignKey("intersections.id"))
    len_between_intersections: Mapped[int]
    avg_speed: Mapped[int]


class OutputData(BaseModel):
    __tablename__ = "output_data"

    id: Mapped[int] = mapped_column(primary_key=True)
    intersection_id: Mapped[int] = mapped_column(ForeignKey("intersections.id"))
    cycle_sec: Mapped[int]
    green_main_sec: Mapped[int]
    green_secondary_sec: Mapped[int]
