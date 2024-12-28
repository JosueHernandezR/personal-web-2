from supabase import create_client, Client
from .config import get_settings
from fastapi import Depends

class SupabaseClient:
    def __init__(self, url: str, key: str):
        self.client = create_client(url, key)

    def table(self, name: str):
        return self.client.table(name)

    def auth(self):
        return self.client.auth

def get_supabase(settings = Depends(get_settings)) -> SupabaseClient:
    return SupabaseClient(settings.SUPABASE_URL, settings.SUPABASE_KEY)