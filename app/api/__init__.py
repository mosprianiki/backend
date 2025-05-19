from fastapi import APIRouter

from app.api.ping.views import router as ping_router

router = APIRouter(prefix="/api")

router.include_router(ping_router)
