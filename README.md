# Proyecto Full Stack con Supabase, FastAPI y Next.js

Este proyecto implementa una arquitectura moderna utilizando Supabase como base de datos y sistema de autenticación, FastAPI para el backend y Next.js para el frontend.

## Estructura del Proyecto

```
mi-proyecto/
├── docker/                     # Configuraciones de Docker
│   ├── supabase/              # Configuración de Supabase
│   ├── frontend/              # Configuración de Next.js
│   ├── backend/               # Configuración de FastAPI
│   └── monitoring/            # Configuración de monitoreo
├── frontend/                   # Aplicación Next.js
├── backend/                    # API FastAPI
├── supabase/                  # Configuración de Supabase
├── docs/                      # Documentación
└── scripts/                   # Scripts útiles
```

## Requisitos Previos

- Docker y Docker Compose
- Node.js (v16 o superior)
- Python 3.8+
- Bash (para scripts de configuración)

## Configuración Inicial

1. Clonar el repositorio:
```bash
git clone <url-del-repositorio>
cd mi-proyecto
```

2. Hacer ejecutable el script de configuración:
```bash
chmod +x scripts/setup-supabase.sh
```

3. Ejecutar el script de configuración:
```bash
./scripts/setup-supabase.sh
```

El script te pedirá:
- Usuario de la base de datos (por defecto: postgres)
- Duración del JWT en segundos (por defecto: 3600)

El script generará automáticamente:
- Claves de API de Supabase (anónima y de servicio)
- Secreto JWT
- Contraseña de la base de datos

Los archivos de configuración se crearán en:
- `.env` (para desarrollo local)
- `docker/supabase/.env` (para contenedores Docker)

## Iniciar el Entorno de Desarrollo

1. Iniciar Supabase:
```bash
cd docker/supabase
docker-compose up -d
```

2. Verificar que los servicios estén funcionando:
- Supabase Studio: http://localhost:3010
- API de Supabase: http://localhost:8000

## Variables de Entorno

Las siguientes variables de entorno son necesarias para el funcionamiento del proyecto:

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| POSTGRES_USER | Usuario de la base de datos | postgres |
| POSTGRES_PASSWORD | Contraseña de la base de datos | (generada) |
| SUPABASE_ANON_KEY | Clave anónima de Supabase | (generada) |
| SUPABASE_SERVICE_KEY | Clave de servicio de Supabase | (generada) |
| JWT_SECRET | Secreto para firmar JWTs | (generada) |
| JWT_EXPIRY | Duración de los JWTs en segundos | 3600 |

## Seguridad

⚠️ **IMPORTANTE**:
- Nunca subas los archivos `.env` al control de versiones
- Mantén las claves generadas en un lugar seguro
- Considera rotar las claves periódicamente en ambientes de producción

## Siguientes Pasos

1. Configurar el frontend con Next.js
2. Configurar el backend con FastAPI
3. Implementar el sistema de monitoreo
4. Configurar CI/CD

## Contribuir

[Instrucciones para contribuir al proyecto...]

## Licencia

[Información de la licencia...]