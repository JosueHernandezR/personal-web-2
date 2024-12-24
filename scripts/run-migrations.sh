#!/bin/bash
# scripts/run-migrations.sh

# Definimos colores para una mejor legibilidad en la terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para cargar variables de entorno
load_env() {
    if [ -f "docker/supabase/.env" ]; then
        # Cargamos las variables del archivo .env
        export $(cat docker/supabase/.env | grep -v '^#' | xargs)
        # Exportamos PGPASSWORD para que psql la use automáticamente
        export PGPASSWORD="$POSTGRES_PASSWORD"
        show_success "Variables de entorno cargadas correctamente"
        show_step "Usuario de base de datos configurado: $POSTGRES_USER"
    else
        show_error "No se encontró el archivo .env en docker/supabase/"
        exit 1
    fi
}

# Función para mostrar mensajes
show_step() { echo -e "${BLUE}==>${NC} $1"; }
show_success() { echo -e "${GREEN}✔${NC} $1"; }
show_error() { echo -e "${RED}✘${NC} $1"; }
show_warning() { echo -e "${YELLOW}!${NC} $1"; }

# Función para ejecutar una migración
run_migration() {
    local file=$1
    local migration_name=$(basename "$file")
    
    show_step "Ejecutando migración: $migration_name"
    show_step "Usando usuario: $POSTGRES_USER en base de datos: postgres"
    
    # Usamos el nombre de base de datos explícito 'postgres'
    if docker compose -f docker/supabase/docker-compose.yml exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" db psql \
        -U "$POSTGRES_USER" \
        -d postgres \
        -f "/docker-entrypoint-initdb.d/$migration_name"; then
        show_success "Migración $migration_name completada exitosamente"
        return 0
    else
        show_error "Error al ejecutar la migración $migration_name"
        show_error "Detalles de conexión:"
        show_error "Usuario: $POSTGRES_USER"
        show_error "Base de datos: postgres"
        show_error "Archivo: $migration_name"
        return 1
    fi
}

# Función para verificar que la base de datos está disponible
check_database() {
    show_step "Verificando conexión a la base de datos..."
    
    # Intentamos hasta 5 veces con un intervalo de 3 segundos
    for i in {1..5}; do
        if docker compose -f docker/supabase/docker-compose.yml exec -T -e PGPASSWORD="$POSTGRES_PASSWORD" db pg_isready \
            -U "$POSTGRES_USER" \
            -d postgres; then
            show_success "Base de datos está lista"
            return 0
        fi
        
        show_warning "Intento $i/5: Base de datos no está lista, esperando..."
        sleep 3
    done
    
    show_error "No se pudo conectar a la base de datos después de 5 intentos"
    return 1
}

# Función principal
main() {
    show_step "Iniciando proceso de migraciones"
    
    # Verificar que estamos en el directorio raíz del proyecto
    if [ ! -d "supabase/migrations" ]; then
        show_error "Este script debe ejecutarse desde el directorio raíz del proyecto"
        exit 1
    fi
    
    # Cargar variables de entorno
    load_env
    
    # Verificar que tenemos las variables necesarias
    if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
        show_error "Faltan variables de entorno necesarias (POSTGRES_USER o POSTGRES_PASSWORD)"
        exit 1
    fi
    
    # Verificar que la base de datos está disponible
    if ! check_database; then
        exit 1
    fi
    
    # Obtener lista de archivos de migración ordenados
    local migrations=($(ls -1 supabase/migrations/*.sql | sort))
    
    if [ ${#migrations[@]} -eq 0 ]; then
        show_warning "No se encontraron archivos de migración"
        exit 0
    fi
    
    show_step "Se encontraron ${#migrations[@]} migraciones para ejecutar"
    
    # Ejecutar cada migración en orden
    for migration in "${migrations[@]}"; do
        if ! run_migration "$migration"; then
            show_error "El proceso de migración se detuvo debido a un error"
            exit 1
        fi
    done
    
    show_success "Todas las migraciones se completadas exitosamente"
}

# Ejecutar el script
main