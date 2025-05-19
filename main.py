from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.docs import (
    get_swagger_ui_html,
    get_swagger_ui_oauth2_redirect_html,
)
from fastapi.responses import HTMLResponse, ORJSONResponse
from fastapi.staticfiles import StaticFiles

from app.api import router as api_router
from app.core.sentry import init_sentry
from app.core.store import Store

store = Store()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
    app.state.store = store

    init_sentry(
        dsn=store.config.sentry.dsn,
        environment=store.config.sentry.environment,
    )

    await app.state.store.db.connect()
    yield
    await app.state.store.db.disconnect()


description = Path("app/API.md").read_text(encoding="utf8")

tags_metadata = [
    {
        "name": "Аутентификация",
        "description": "Основная аутентификация",
    },
]

app = FastAPI(
    title="zit API",
    description=description,
    version="1.0.0",
    lifespan=lifespan,
    default_response_class=ORJSONResponse,
    openapi_url="/api/openapi.json",
    docs_url=None,
    redoc_url=None,
    openapi_tags=tags_metadata,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)
app.mount("/static", StaticFiles(directory=store.config.static_dir), name="static")


@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html() -> HTMLResponse:
    return get_swagger_ui_html(
        openapi_url="/api/openapi.json",
        title=app.title,
        oauth2_redirect_url=app.swagger_ui_oauth2_redirect_url,
        swagger_js_url="/static/swagger-ui-bundle.js",
        swagger_css_url="/static/swagger-ui.css",
        swagger_ui_parameters={
            "tryItOutEnabled": store.config.swagger.disable_try_it_out_button,
        },
    )


@app.get("/docs/oauth2-redirect", include_in_schema=False)
async def swagger_ui_redirect() -> HTMLResponse:
    return get_swagger_ui_oauth2_redirect_html()
