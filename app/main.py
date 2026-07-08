from fastapi import FastAPI

from app.routers import items

app = FastAPI(title="fastapi-fargate")

app.include_router(items.router)


@app.get("/")
async def root() -> dict[str, str]:
    # Kept free of the database so the ALB health check never fails because
    # of a slow/unavailable RDS instance.
    return {"status": "ok"}
