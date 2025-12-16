# Low-Code Stack - Ansible Deployment

Coleccion profesional de Ansible para desplegar un stack completo de desarrollo low-code/no-code en Ubuntu 24.04 LTS.

## Arquitectura del Stack

El stack esta organizado en dos capas: **Core** (servicios base obligatorios) y **Optional** (servicios complementarios habilitables).

### Core Stack (siempre desplegado)

- **Supabase** - Backend as a Service (PostgreSQL, Auth, Storage, Realtime)
- **Appsmith** - Constructor de aplicaciones low-code (con patch de watermark)
- **n8n** - Automatizacion de workflows
- **Redis** - Cache para n8n y Docmost
- **Nginx** - Reverse proxy con SSL (Let's Encrypt)

### Servicios Opcionales (habilitables)

- **Gitea** - Servidor Git auto-hospedado (usa PostgreSQL propio)
- **Docmost** - Plataforma de documentacion colaborativa (usa PostgreSQL y Redis propios)
- **Moodle** - Sistema de gestion de aprendizaje (LMS) con MariaDB propio
- **Windmill** - Plataforma de desarrollo (scripts, workflows, UI) con PostgreSQL propio

## Caracteristicas

- **Secretos auto-generados**: No necesitas configurar contraseñas manualmente
- **100% replicable**: Clona, configura dominio/IP y despliega
- **Docker integrado**: Contenedor Ansible incluido para Windows/macOS
- **SSL automatico**: Certificados Let's Encrypt configurados automaticamente

## Requisitos

- **Control Node**: Docker (Windows/macOS) o Python 3.10+ con Ansible (Linux)
- **Target Node**: Ubuntu 24.04 LTS
- **Dominios**: Configurados apuntando al servidor (DNS)
- **Puertos**: 22 (SSH), 80 (HTTP), 443 (HTTPS)

## Quick Start

### 1. Clonar y construir

```bash
git clone https://github.com/benabhi/lowcode-stack.git
cd lowcode-stack

# Construir contenedor Ansible
docker compose build
```

### 2. Configurar

Editar `inventory/production/hosts.yml`:

```yaml
lowcode-prod:
  ansible_host: TU_IP_AQUI
  ansible_user: root
```

Editar `inventory/production/group_vars/all.yml`:

```yaml
lowcode_domain_base: "tudominio.com"
lowcode_letsencrypt_email: "admin@tudominio.com"
```

### 3. Desplegar

```bash
# Con contraseña SSH:
docker compose run --rm ansible playbooks/site.yml --ask-pass

# Con SSH key:
docker compose run --rm ansible playbooks/site.yml
```

**Listo!** Los secretos se generan automaticamente y se muestran en pantalla para que los guardes.

## Estructura del Proyecto

```
.
├── Dockerfile                  # Contenedor Ansible
├── docker-compose.yml          # Orquestacion Docker
├── ansible.cfg                 # Configuracion Ansible
├── requirements.yml            # Dependencias Galaxy
├── inventory/
│   └── production/
│       ├── hosts.yml           # Servidores
│       └── group_vars/
│           └── all.yml         # Variables configurables
├── playbooks/
│   ├── site.yml                # Despliegue completo
│   ├── setup.yml               # Solo sistema
│   └── deploy.yml              # Solo servicios
└── roles/
    ├── secrets/                # Auto-generacion de secretos
    ├── common/                 # Sistema base, UFW
    ├── redis/                  # Cache (core)
    ├── supabase/               # Backend (core)
    ├── appsmith/               # Low-code builder (core)
    ├── n8n/                    # Workflows (core)
    ├── nginx/                  # Reverse proxy + SSL (core)
    ├── gitea/                  # Git server (optional)
    ├── docmost/                # Documentation (optional)
    ├── moodle/                 # LMS platform (optional)
    └── windmill/               # Developer platform (optional)
```

## Comandos Utiles

```bash
# Verificar conexion
docker compose run --rm ansible all -m ping --ask-pass

# Despliegue completo (core + optional habilitados)
docker compose run --rm ansible playbooks/site.yml --ask-pass

# Solo core stack
docker compose run --rm ansible playbooks/site.yml --tags core --ask-pass

# Solo servicios opcionales
docker compose run --rm ansible playbooks/site.yml --tags optional --ask-pass

# Solo servicios (servidor ya configurado)
docker compose run --rm ansible playbooks/deploy.yml --ask-pass

# Dry run (sin cambios)
docker compose run --rm ansible playbooks/site.yml --check --diff --ask-pass

# Solo un servicio especifico
docker compose run --rm ansible playbooks/site.yml --tags supabase --ask-pass
docker compose run --rm ansible playbooks/site.yml --tags gitea --ask-pass
docker compose run --rm ansible playbooks/site.yml --tags docmost --ask-pass
docker compose run --rm ansible playbooks/site.yml --tags moodle --ask-pass
docker compose run --rm ansible playbooks/site.yml --tags windmill --ask-pass

# Reaplicar patch de watermark
docker compose run --rm ansible playbooks/site.yml --tags watermark --ask-pass

# Shell interactivo
docker compose run --rm --entrypoint bash ansible
```

## Servicios Opcionales

Los servicios opcionales se habilitan/deshabilitan en `inventory/production/group_vars/all.yml`:

```yaml
# ==============================================================================
# OPTIONAL SERVICES - Enable/Disable
# ==============================================================================
lowcode_enable_gitea: true      # Git server
lowcode_enable_docmost: true    # Documentation platform
lowcode_enable_moodle: true     # LMS platform (Moodle)
lowcode_enable_windmill: true   # Developer platform (Windmill)
```

### Dominios por defecto

| Servicio | Dominio |
|----------|---------|
| Gitea    | `gitea.{lowcode_domain_base}` |
| Docmost  | `docmost.{lowcode_domain_base}` |
| Moodle   | `moodle.{lowcode_domain_base}` |
| Windmill | `windmill.{lowcode_domain_base}` |

### Arquitectura Independiente

Los servicios opcionales tienen sus propios contenedores de base de datos y cache:

- **Gitea**: PostgreSQL propio (`gitea-db`) - independiente de Supabase
- **Docmost**: PostgreSQL propio (`docmost-db`) + Redis propio (`docmost-redis`)
- **Moodle**: MariaDB propio (`moodle-db`) - completamente independiente
- **Windmill**: PostgreSQL propio (`windmill-db`) + Workers + LSP
- **n8n**: Redis propio (`n8n-redis`) para colas
- Todos comparten la red Docker `lowcode-network` para comunicacion interna

### ⚠️ Servicios Core (Solo Desarrollo)

**IMPORTANTE**: Los siguientes servicios del core son **solo para desarrollo** y NO deben ser utilizados por otros contenedores o servicios:

| Servicio | Contenedor | Proposito |
|----------|------------|-----------|
| Supabase PostgreSQL | `supabase-db` | Base de datos de Supabase - solo para desarrollo y pruebas |
| Redis compartido | `lowcode-redis` | Cache de desarrollo - no usar en produccion |

Los servicios opcionales (Gitea, Docmost, n8n) tienen sus propios contenedores de base de datos y cache para garantizar aislamiento y estabilidad en produccion.

## Configuracion

### Variables Principales (`all.yml`)

```yaml
# Servidor
lowcode_server_ip: "72.62.13.157"
lowcode_base_path: "/opt/lowcode-stack"
lowcode_timezone: "America/Argentina/Buenos_Aires"

# Dominios
lowcode_domain_base: "tudominio.com"
lowcode_domain_supabase: "supabase.{{ lowcode_domain_base }}"
lowcode_domain_n8n: "n8n.{{ lowcode_domain_base }}"
lowcode_domain_appsmith: "appsmith.{{ lowcode_domain_base }}"

# Versiones
lowcode_supabase_version: "latest"
lowcode_appsmith_version: "latest"
lowcode_n8n_version: "latest"
```

## Secretos Auto-generados

En el primer despliegue, Ansible genera automaticamente todos los secretos:

- Contraseñas de PostgreSQL, Redis
- JWT secrets de Supabase
- Claves de encriptacion de n8n y Appsmith
- Credenciales de Basic Auth para Nginx

Los secretos se:
1. **Muestran en pantalla** para que los guardes
2. **Guardan en el servidor** en `/opt/lowcode-stack/.secrets.yml`
3. **Reutilizan** en despliegues posteriores

## Watermark de Appsmith

El rol de Appsmith incluye un patch automatico para remover la marca de agua.

**Importante**: El patch NO es persistente. Se debe reaplicar despues de actualizar/reiniciar el contenedor:

```bash
docker compose run --rm ansible playbooks/site.yml --tags watermark --ask-pass
```

## SSL/HTTPS

Los certificados SSL se generan automaticamente con Let's Encrypt.

- Renovacion automatica (cron job diario)
- Para testing: `nginx_certbot_staging: true` en `all.yml`

## Comunicación Interna entre Servicios

Todos los servicios están en la red Docker `lowcode-network` y pueden comunicarse entre sí usando los siguientes hostnames internos:

### Core Services

| Servicio | Hostname Interno | Puerto | Descripción |
|----------|------------------|--------|-------------|
| Supabase API | `supabase-kong` | 8000 | API REST y GraphQL |
| Supabase DB | `supabase-db` | 5432 | PostgreSQL directo |
| Supabase Studio | `supabase-studio` | 3000 | UI de administración |
| n8n | `lowcode-n8n` | 5678 | Workflow automation |
| Appsmith | `lowcode-appsmith` | 80 | Low-code builder |
| Redis | `lowcode-redis` | 6379 | Cache |

### Optional Services

| Servicio | Hostname Interno | Puerto | Descripción |
|----------|------------------|--------|-------------|
| Gitea | `lowcode-gitea` | 3000 | Git server (SSH: 22) |
| Docmost | `lowcode-docmost` | 3000 | Documentation platform |
| Moodle | `lowcode-moodle` | 8080 | LMS platform |
| Windmill | `lowcode-windmill-server` | 8000 | Developer platform |

### Ejemplo: Conectar n8n a Supabase

En n8n, usa estas URLs para conectar con Supabase:

```
# API REST
http://supabase-kong:8000/rest/v1/

# Headers requeridos:
apikey: <tu_anon_key>
Authorization: Bearer <tu_anon_key>
```

### Ejemplo: Conectar Appsmith a Supabase

En Appsmith, crea una nueva datasource PostgreSQL:

```
Host: supabase-db
Port: 5432
Database: postgres
User: postgres
Password: <supabase_postgres_password>
```

### Claves de API de Supabase

Las claves JWT se encuentran en `/opt/lowcode-stack/.secrets.yml`:

- `supabase_anon_key`: Para operaciones públicas (respeta RLS)
- `supabase_service_role_key`: Acceso completo (bypass RLS) - **usar con cuidado**

## Exponer Nuevas URLs Públicas

Para exponer un nuevo servicio públicamente, edita `inventory/production/group_vars/all.yml`:

```yaml
nginx_sites:
  # ... servicios existentes ...

  - name: "mi-servicio"
    domain: "mi-servicio.tudominio.com"
    upstream_host: "127.0.0.1"
    upstream_port: 3001
    basic_auth: false
    websocket: false
    max_body_size: "10M"
```

Luego ejecuta:

```bash
docker compose run --rm ansible playbooks/site.yml --tags nginx --ask-pass
```

## Seguridad

- Firewall (UFW) - Solo SSH, HTTP, HTTPS
- SSL/TLS 1.2+ solamente
- HSTS habilitado
- Headers de seguridad en Nginx
- Basic Auth para Supabase Studio
- Secretos protegidos en el servidor (modo 600)

## Troubleshooting

### Certificados SSL no se generan

1. Verificar DNS: `nslookup tudominio.com`
2. Verificar puertos abiertos: 80 y 443
3. Usar staging para testing: `nginx_certbot_staging: true`

### Appsmith watermark sigue visible

1. Limpiar cache del navegador (Ctrl+Shift+F5)
2. Reaplicar patch: `--tags watermark`

### Servicios no inician

```bash
# Ver logs
ssh root@servidor "docker logs lowcode-supabase-db"
ssh root@servidor "docker logs lowcode-appsmith"
ssh root@servidor "docker logs lowcode-n8n"
```

## Instalacion Alternativa (Linux nativo)

```bash
# Instalar Ansible
sudo apt update && sudo apt install -y python3 python3-pip python3-venv
python3 -m venv venv
source venv/bin/activate
pip install ansible

# Instalar dependencias
ansible-galaxy install -r requirements.yml

# Desplegar
ansible-playbook playbooks/site.yml --ask-pass
```

## Licencia

MIT

## Autor

lowcode-stack
