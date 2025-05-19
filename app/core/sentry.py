import sentry_sdk


def init_sentry(*, dsn: str | None, environment: str | None) -> None:
    sentry_sdk.init(
        dsn=dsn,
        send_default_pii=True,
        traces_sample_rate=1.0,
        profile_session_sample_rate=1.0,
        profile_lifecycle="trace",
        environment=environment,
    )
