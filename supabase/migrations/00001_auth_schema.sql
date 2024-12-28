-- supabase/migrations/00001_auth_schema.sql

-- Crear el esquema de autenticación si no existe
CREATE SCHEMA IF NOT EXISTS auth;

-- Crear la tabla de usuarios
CREATE TABLE IF NOT EXISTS auth.users (
    id uuid NOT NULL PRIMARY KEY,
    instance_id uuid,
    email character varying(255),
    encrypted_password character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamptz,
    recovery_token character varying(255),
    recovery_sent_at timestamptz,
    created_at timestamptz,
    updated_at timestamptz,
    email_confirmed_at timestamptz,
    banned_until timestamptz,
    confirmation_sent_at timestamptz,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    reauthentication_token character varying(255),
    reauthentication_sent_at timestamptz,
    last_sign_in_at timestamptz,
    is_super_admin boolean,
    phone character varying(255),
    phone_confirmed_at timestamptz,
    phone_change character varying(255),
    phone_change_token character varying(255),
    phone_change_sent_at timestamptz,
    email_change character varying(255),
    email_change_token character varying(255),
    email_change_sent_at timestamptz,
    CONSTRAINT users_email_key UNIQUE (email)
);

-- Crear índices necesarios
CREATE INDEX IF NOT EXISTS users_instance_id_email_idx ON auth.users (instance_id, email);
CREATE INDEX IF NOT EXISTS users_instance_id_idx ON auth.users (instance_id);

-- Crear tipos de enum necesarios
DO $$ BEGIN
    CREATE TYPE auth.aal_level AS ENUM ('aal1', 'aal2', 'aal3');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE auth.factor_type AS ENUM ('totp', 'webauthn');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE auth.factor_status AS ENUM ('unverified', 'verified');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Crear tabla de factores de autenticación
CREATE TABLE IF NOT EXISTS auth.mfa_factors (
    id uuid NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    secret text,
    CONSTRAINT mfa_factors_user_friendly_name_key UNIQUE (user_id, friendly_name)
);

-- Crear tabla de desafíos
CREATE TABLE IF NOT EXISTS auth.mfa_challenges (
    id uuid NOT NULL PRIMARY KEY,
    factor_id uuid NOT NULL REFERENCES auth.mfa_factors(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL,
    verified_at timestamptz,
    ip_address inet NOT NULL
);

-- Crear tabla de amr (Authentication Methods References)
CREATE TABLE IF NOT EXISTS auth.mfa_amr_claims (
    id uuid NOT NULL PRIMARY KEY,
    session_id uuid NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    authentication_method text NOT NULL,
    CONSTRAINT mfa_amr_claims_session_id_authentication_method_key UNIQUE (session_id, authentication_method)
);

-- Crear las funciones necesarias para el manejo de usuarios
CREATE OR REPLACE FUNCTION auth.uid() 
RETURNS uuid 
LANGUAGE sql 
STABLE
AS $$
  select 
    coalesce(
        current_setting('request.jwt.claim.sub', true),
        (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')
    )::uuid
$$;