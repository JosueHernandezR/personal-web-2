#!/bin/bash
# scripts/setup.sh

# Asegurar que estamos en el directorio correcto
cd "$(dirname "$0")/.."

# Crear directorios necesarios si no existen
mkdir -p supabase/{config,migrations,seeds,functions}

# Generar claves seguras
generate_key() {
    openssl rand -base64 32
}

# Crear archivo .env en docker/supabase
cat > docker/supabase/.env << EOL
POSTGRES_PASSWORD=$(generate_key)
POSTGRES_USER=postgres
SUPABASE_ANON_KEY=$(generate_key)
SUPABASE_SERVICE_KEY=$(generate_key)
JWT_SECRET=$(generate_key)
JWT_EXPIRY=3600
SITE_URL=http://localhost:3000
API_EXTERNAL_URL=http://localhost:8000
EOL

echo "Configuración inicial completada."
echo "Las claves se han generado y guardado en docker/supabase/.env"
echo "Asegúrate de no compartir o subir este archivo a control de versiones."

# Crear archivo de migración inicial
cat > supabase/migrations/00001_initial_setup.sql << EOL
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

-- Create basic schema
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS auth;

-- Basic user table example
CREATE TABLE IF NOT EXISTS public.users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
EOL

echo "Migración inicial creada en supabase/migrations/00001_initial_setup.sql"