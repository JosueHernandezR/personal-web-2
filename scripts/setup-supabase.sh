#!/bin/bash
# scripts/setup-supabase.sh

# Definimos colores para una mejor legibilidad
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para generar una clave segura
generate_key() {
    openssl rand -base64 32
}

echo -e "${GREEN}=== Configuración de Supabase ===${NC}"

# Verificar si existen archivos .env
if [ -f ".env" ] || [ -f "docker/supabase/.env" ]; then
    echo -e "${RED}Se encontraron archivos .env existentes.${NC}"
    read -p "¿Desea sobrescribirlos? (s/n): " confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        echo "Operación cancelada."
        exit 1
    fi
fi

# Solicitamos solo la duración del JWT ya que el usuario será 'postgres' por defecto
read -p "Duración del JWT en segundos (presione Enter para usar 3600): " JWT_EXPIRY
JWT_EXPIRY=${JWT_EXPIRY:-3600}

# Generamos las claves de manera segura
POSTGRES_PASSWORD=$(generate_key)
SUPABASE_ANON_KEY=$(generate_key)
SUPABASE_SERVICE_KEY=$(generate_key)
JWT_SECRET=$(generate_key)

# Crear contenido del archivo .env con valores estandarizados
ENV_CONTENT="# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# API Keys
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
SUPABASE_SERVICE_KEY=$SUPABASE_SERVICE_KEY

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=$JWT_EXPIRY

# URLs
SITE_URL=http://localhost:3000
API_EXTERNAL_URL=http://localhost:8000
ADDITIONAL_REDIRECT_URLS=

# Timestamp de generación
# Generado: $(date '+%Y-%m-%d %H:%M:%S')"

# Crear directorio si no existe
mkdir -p docker/supabase

# Guardar archivos
echo "$ENV_CONTENT" > .env
echo "$ENV_CONTENT" > docker/supabase/.env

echo -e "${GREEN}✔ Configuración completada${NC}"
echo -e "${BLUE}Archivos generados:${NC}"
echo "- .env"
echo "- docker/supabase/.env"
echo
echo "Configuración:"
echo -e "Usuario BD: ${BLUE}postgres${NC} (usuario estándar de Supabase)"
echo -e "Duración JWT: ${BLUE}$JWT_EXPIRY segundos${NC}"
echo
echo -e "${YELLOW}¡IMPORTANTE!${NC}"
echo "1. El usuario 'postgres' es el superusuario estándar de Supabase"
echo "2. La seguridad se maneja a través de:"
echo "   - Contraseñas generadas aleatoriamente"
echo "   - Políticas de Row Level Security (RLS)"
echo "   - Roles de usuario específicos para la aplicación"
echo "3. Los usuarios de la aplicación nunca usarán directamente estas credenciales"