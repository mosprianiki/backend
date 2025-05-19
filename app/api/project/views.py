from fastapi import APIRouter

from app.api.ping.schemas import PingPublic

router = APIRouter(prefix="/projects", tags=["Проекты"])


@router.post(
    "",
    summary="Создание проекта",
    response_description="Успешный ответ",
)
async def ping() -> PingPublic:
    return PingPublic()
