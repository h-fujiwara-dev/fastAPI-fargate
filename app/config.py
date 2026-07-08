from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="DB_")

    # Field names line up with the DB_* environment variables the ECS task
    # definition injects (see modules/ecs/main.tf).
    host: str = "localhost"
    port: int = 5432
    name: str = "app"
    username: str = "app_admin"
    password: str = ""

    @property
    def database_url(self) -> str:
        return f"postgresql+asyncpg://{self.username}:{self.password}@{self.host}:{self.port}/{self.name}"


settings = Settings()
