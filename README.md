# Low-Code Docker Suite

Suite de desarrollo low-code con Docker que incluye:

- **Supabase** - Backend as a Service (Postgres, Auth, Storage, Realtime, API)
- **Appsmith** - Constructor de aplicaciones low-code
- **n8n** - Automatización de workflows
- **Redis** - Cache para n8n

## Requisitos

- [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)
- [Git](https://git-scm.com/downloads)
- PowerShell 5.1+

## Instalación Rápida

```powershell
# 1. Clonar el repositorio
git clone <tu-repo-url> nocode
cd nocode

# 2. Ejecutar setup (clona Supabase y configura todo)
.\setup.ps1

# 3. Iniciar servicios
.\start.ps1
```

## URLs de Servicios

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Supabase Studio | http://localhost:3000 | Panel de administración de Supabase |
| Supabase API | http://localhost:8000 | API Gateway (Kong) |
| Appsmith | http://localhost:8081 | Constructor de apps low-code |
| n8n | http://localhost:5678 | Automatización de workflows |
| PostgreSQL | localhost:5432 | Base de datos (via Supabase) |

## Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `setup.ps1` | Configura el proyecto (clonar Supabase, crear .env) |
| `setup.ps1 -GenerateSecrets` | Setup con generación automática de secretos |
| `start.ps1` | Inicia todos los servicios (incluye patch de watermark) |
| `stop.ps1` | Detiene todos los servicios |
| `stop.ps1 -RemoveVolumes` | Detiene y elimina todos los datos |
| `remove-appsmith-watermark.ps1` | Aplica manualmente el patch para quitar watermark |

## Configuración

### Supabase

Editar `supabase/.env` para configurar:
- `POSTGRES_PASSWORD` - Contraseña de la base de datos
- `JWT_SECRET` - Secreto para tokens JWT
- `ANON_KEY` - API key pública
- `SERVICE_ROLE_KEY` - API key privada

> ⚠️ **Importante**: Cambia los secretos antes de usar en producción.
> Genera claves JWT en: https://supabase.com/docs/guides/self-hosting/docker#generate-and-configure-api-keys

### n8n con Postgres

Para usar Postgres de Supabase en n8n, editar `services/docker-compose.yml` y descomentar las variables de `DB_POSTGRESDB_*`.

### Appsmith con Supabase

Configurar la conexión a Postgres desde la UI de Appsmith:
- Host: `host.docker.internal`
- Port: `5432`
- Database: `postgres`
- User: `postgres`
- Password: (el de `supabase/.env`)

### Appsmith Watermark

El watermark "Built on Appsmith" se elimina automáticamente al ejecutar `start.ps1`.
Si necesitas aplicar el patch manualmente después de recrear el container:
```powershell
.\remove-appsmith-watermark.ps1
```

## Estructura del Proyecto

```
nocode/
├── setup.ps1                      # Script de configuración inicial
├── start.ps1                      # Iniciar servicios
├── stop.ps1                       # Detener servicios
├── remove-appsmith-watermark.ps1  # Patch para quitar watermark
├── README.md                      # Esta documentación
├── supabase/                      # (generado por setup.ps1)
│   ├── docker-compose.yml
│   ├── docker-compose.override.yml
│   ├── .env
│   └── volumes/
└── services/
    └── docker-compose.yml         # Appsmith + n8n + Redis
```

## Troubleshooting

### Los servicios no inician
```powershell
# Ver logs de un servicio específico
docker compose -f supabase/docker-compose.yml logs -f
docker compose -f services/docker-compose.yml logs -f
```

### Reiniciar desde cero
```powershell
.\stop.ps1 -RemoveVolumes
.\setup.ps1
.\start.ps1
```

### Supabase tarda en iniciar
Es normal, especialmente la primera vez. Espera 1-2 minutos y verifica con:
```powershell
docker compose -f supabase/docker-compose.yml ps
```

## Licencia

MIT
