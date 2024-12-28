from functools import lru_cache
from typing import Literal
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Configuración básica
    APP_NAME: str = "FastAPI Backend"
    ENVIRONMENT: Literal["development", "production", "test"] = "development"
    DEBUG: bool = True

    # Configuración de Supabase
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_JWT_SECRET: str

    # Configuración de base de datos
    DATABASE_URL: str

    class Config:
        env_file = ".env"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    return Settings()