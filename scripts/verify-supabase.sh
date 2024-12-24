#!/bin/bash
# scripts/verify-supabase.sh

# Colores para la salida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Verificando la configuración de Supabase ===${NC}"

# Verificar que los archivos necesarios existen
check_files() {
    local missing_files=0
    
    echo "Verificando archivos necesarios..."
    
    # Lista de archivos requeridos
    files=(
        ".env"
        "docker/supabase/.env"
        "supabase/migrations/00001_initial_setup.sql"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "✔ $file ${GREEN}encontrado${NC}"
        else
            echo -e "✘ $file ${RED}no encontrado${NC}"
            missing_files=$((missing_files + 1))
        fi
    done
    
    return $missing_files
}

# Verificar que Docker está corriendo
check_docker() {
    echo "Verificando Docker..."
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}✘ Docker no está corriendo${NC}"
        return 1
    fi
    echo -e "${GREEN}✔ Docker está corriendo${NC}"
    return 0
}

# Verificar servicios de Supabase
check_supabase_services() {
    echo "Verificando servicios de Supabase..."
    
    services=("supabase-db" "supabase-kong" "supabase-studio")
    local failed_services=0
    
    for service in "${services[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "$service"; then
            echo -e "✔ $service ${GREEN}está corriendo${NC}"
        else
            echo -e "✘ $service ${RED}no está corriendo${NC}"
            failed_services=$((failed_services + 1))
        fi
    done
    
    return $failed_services
}

# Ejecutar todas las verificaciones
main() {
    local has_errors=0
    
    # Verificar archivos
    if ! check_files; then
        echo -e "${RED}Faltan archivos necesarios${NC}"
        has_errors=1
    fi
    
    # Verificar Docker
    if ! check_docker; then
        echo -e "${RED}Por favor, inicia Docker y vuelve a intentar${NC}"
        has_errors=1
    fi
    
    # Si Docker está corriendo, verificar servicios
    if [ $has_errors -eq 0 ]; then
        if ! check_supabase_services; then
            echo -e "${RED}Algunos servicios no están corriendo${NC}"
            echo "Puedes intentar iniciarlos con:"
            echo "cd docker/supabase && docker-compose up -d"
            has_errors=1
        fi
    fi
    
    if [ $has_errors -eq 0 ]; then
        echo -e "\n${GREEN}✔ Todo está correctamente configurado${NC}"
        echo -e "${BLUE}Puedes acceder a:${NC}"
        echo "- Supabase Studio: http://localhost:3010"
        echo "- API: http://localhost:8000"
    else
        echo -e "\n${RED}✘ Se encontraron algunos problemas${NC}"
        echo "Por favor, corrige los errores mencionados arriba"
    fi
}

# Ejecutar el script
main