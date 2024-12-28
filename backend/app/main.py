from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .core.config import Settings, get_settings
from .core.supabase import SupabaseClient, get_supabase
from .core.auth import get_current_user
from .api import router

app = FastAPI(title="FastAPI Backend")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configura esto apropiadamente en producción
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir routers
app.include_router(router, prefix="/api")

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/protected")
async def protected_route(current_user: dict = Depends(get_current_user)):
    return {"message": "This is a protected route", "user": current_user}

@app.get("/supabase-test")
async def test_supabase(supabase: SupabaseClient = Depends(get_supabase)):
    try:
        # Intenta hacer una consulta simple a Supabase
        result = supabase.table("profiles").select("*").limit(1).execute()
        return {"message": "Supabase connection successful", "data": result.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Supabase connection failed: {str(e)}")