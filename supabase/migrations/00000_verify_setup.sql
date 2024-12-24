-- supabase/migrations/00000_verify_setup.sql

-- Esta función nos ayudará a verificar si una extensión está instalada
CREATE OR REPLACE FUNCTION verify_extension(extension_name TEXT) 
RETURNS TEXT AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = extension_name
    ) THEN
        RETURN extension_name || ' ya está instalada';
    ELSE
        -- Intentamos instalar la extensión
        EXECUTE 'CREATE EXTENSION IF NOT EXISTS "' || extension_name || '"';
        RETURN extension_name || ' ha sido instalada';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Verificamos e instalamos las extensiones necesarias
SELECT verify_extension('uuid-ossp');      -- Para generar UUIDs
SELECT verify_extension('pgcrypto');       -- Para funciones criptográficas
SELECT verify_extension('pgjwt');          -- Para manejar JWT tokens
SELECT verify_extension('moddatetime');    -- Para timestamps automáticos

-- Configuramos los esquemas necesarios
DO $$ 
BEGIN
    -- Esquema público
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'public'
    ) THEN
        CREATE SCHEMA public;
    END IF;

    -- Esquema de autenticación
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth'
    ) THEN
        CREATE SCHEMA auth;
    END IF;

    -- Esquema de almacenamiento
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage'
    ) THEN
        CREATE SCHEMA storage;
    END IF;
END $$;

-- Configuramos la búsqueda de esquemas
ALTER DATABASE postgres SET search_path TO public, auth, storage;

-- Verificamos que el RLS (Row Level Security) está habilitado en las tablas públicas
CREATE OR REPLACE FUNCTION verify_rls_enabled() 
RETURNS TEXT[] AS $$
DECLARE
    tables_without_rls TEXT[];
    table_record RECORD;
BEGIN
    tables_without_rls := ARRAY[]::TEXT[];
    
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_tables 
            WHERE tablename = table_record.tablename 
            AND rowsecurity = true
        ) THEN
            tables_without_rls := array_append(
                tables_without_rls, 
                table_record.tablename
            );
            
            -- Habilitamos RLS en la tabla
            EXECUTE 'ALTER TABLE public.' || 
                    quote_ident(table_record.tablename) || 
                    ' ENABLE ROW LEVEL SECURITY';
        END IF;
    END LOOP;
    
    RETURN tables_without_rls;
END;
$$ LANGUAGE plpgsql;

-- Ejecutamos la verificación de RLS
SELECT verify_rls_enabled() as tables_updated;

-- Creamos roles básicos si no existen
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN NOINHERIT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN NOINHERIT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN NOINHERIT;
    END IF;
END $$;

-- Otorgamos permisos básicos
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Verificación final
SELECT 
    current_database() as database,
    current_user as current_user,
    session_user as session_user,
    current_setting('search_path') as search_path;