-- Habilitamos las extensiones necesarias para Supabase
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pgjwt";
CREATE EXTENSION IF NOT EXISTS "moddatetime";

-- Creamos un trigger helper para manejar los timestamps
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ejemplo de una tabla de perfiles extendida
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    website TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT username_length CHECK (char_length(username) >= 3)
);

-- Configuramos RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Creamos políticas de seguridad para la tabla profiles de manera condicional
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Profiles are viewable by everyone'
        AND tablename = 'profiles'
    ) THEN
        CREATE POLICY "Profiles are viewable by everyone"
            ON public.profiles
            FOR SELECT USING (true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own profile'
        AND tablename = 'profiles'
    ) THEN
        CREATE POLICY "Users can insert their own profile"
            ON public.profiles
            FOR INSERT
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own profile'
        AND tablename = 'profiles'
    ) THEN
        CREATE POLICY "Users can update their own profile"
            ON public.profiles
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Crear trigger para profiles si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'handle_profiles_updated_at'
    ) THEN
        CREATE TRIGGER handle_profiles_updated_at
            BEFORE UPDATE ON public.profiles
            FOR EACH ROW
            EXECUTE FUNCTION handle_updated_at();
    END IF;
END $$;

-- Tabla de posts
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT,
    published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT title_length CHECK (char_length(title) >= 3)
);

-- Configuramos RLS para posts
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para posts de manera condicional
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Public posts are viewable by everyone'
        AND tablename = 'posts'
    ) THEN
        CREATE POLICY "Public posts are viewable by everyone"
            ON public.posts
            FOR SELECT USING (published = true);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own unpublished posts'
        AND tablename = 'posts'
    ) THEN
        CREATE POLICY "Users can view their own unpublished posts"
            ON public.posts
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can create their own posts'
        AND tablename = 'posts'
    ) THEN
        CREATE POLICY "Users can create their own posts"
            ON public.posts
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own posts'
        AND tablename = 'posts'
    ) THEN
        CREATE POLICY "Users can update their own posts"
            ON public.posts
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete their own posts'
        AND tablename = 'posts'
    ) THEN
        CREATE POLICY "Users can delete their own posts"
            ON public.posts
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Crear trigger para posts si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'handle_posts_updated_at'
    ) THEN
        CREATE TRIGGER handle_posts_updated_at
            BEFORE UPDATE ON public.posts
            FOR EACH ROW
            EXECUTE FUNCTION handle_updated_at();
    END IF;
END $$;

-- Crear la función handle_new_user si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user'
    ) THEN
        EXECUTE 'CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS TRIGGER AS $trigger$
        BEGIN
            INSERT INTO public.profiles (user_id, username, full_name)
            VALUES (
                NEW.id,
                NEW.raw_user_meta_data->>''username'',
                NEW.raw_user_meta_data->>''full_name''
            );
            RETURN NEW;
        END;
        $trigger$ LANGUAGE plpgsql SECURITY DEFINER';
    END IF;
END $$;

-- Crear el trigger on_auth_user_created si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created'
    ) THEN
        CREATE TRIGGER on_auth_user_created
            AFTER INSERT ON auth.users
            FOR EACH ROW
            EXECUTE FUNCTION public.handle_new_user();
    END IF;
END $$;