# Low-Code Stack - Ansible Deployment

Coleccion profesional de Ansible para desplegar un stack completo de desarrollo low-code/no-code en Ubuntu 24.04 LTS.

## Servicios Incluidos

- **Supabase** - Backend as a Service (PostgreSQL, Auth, Storage, Realtime)
- **Appsmith** - Constructor de aplicaciones low-code (con patch de watermark)
- **n8n** - Automatizacion de workflows
- **Redis** - Cache para n8n
- **Nginx** - Reverse proxy con SSL (Let's Encrypt)

## Requisitos

- **Control Node**: Docker (Windows/macOS) o Python 3.10+ con Ansible (Linux)
- **Target Node**: Ubuntu 24.04 LTS
- **Dominios**: Configurados apuntando al servidor (DNS)
- **Puertos**: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **SSH Key**: Configurada para acceso al servidor

## Instalacion

### Opcion 1: Docker (Recomendado para Windows/macOS)

El proyecto incluye un contenedor Docker con Ansible preconfigurado.

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/lowcode-stack.git
cd lowcode-stack

# Construir el contenedor
docker compose build

# Verificar que funciona
docker compose run --rm ansible --help

# Verificar conexion al servidor
docker compose run --rm ansible all -m ping
```

**Comandos principales:**

```bash
# Despliegue completo
docker compose run --rm ansible playbooks/site.yml --ask-vault-pass

# Solo setup del sistema
docker compose run --rm ansible playbooks/setup.yml

# Solo servicios
docker compose run --rm ansible playbooks/deploy.yml --ask-vault-pass

# Dry run (sin cambios)
docker compose run --rm ansible playbooks/site.yml --check --diff

# Shell interactivo
docker compose run --rm --entrypoint bash ansible
```

### Opcion 2: Virtualenv (Linux/macOS)

```bash
# Instalar Python y venv
# Ubuntu/Debian:
sudo apt update && sudo apt install -y python3 python3-pip python3-venv

# macOS:
brew install python3

# Crear y activar virtualenv
python3 -m venv venv
source venv/bin/activate

# Instalar Ansible
pip install --upgrade pip
pip install ansible

# Verificar instalacion
ansible --version

# Instalar roles de Galaxy
ansible-galaxy install -r requirements.yml
```

### Opcion 3: Gestor de paquetes del sistema

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y ansible

# macOS con Homebrew
brew install ansible

# Instalar roles de Galaxy
ansible-galaxy install -r requirements.yml
```

## Quick Start

### 1. Clonar y construir

```bash
git clone https://github.com/tu-usuario/lowcode-stack.git
cd lowcode-stack

# Si usas Docker (Windows/macOS):
docker compose build

# Si usas virtualenv (Linux):
# source venv/bin/activate && ansible-galaxy install -r requirements.yml
```

### 2. Configurar el inventario

Editar `inventory/production/hosts.yml`:

```yaml
all:
  children:
    lowcode_servers:
      hosts:
        lowcode-prod:
          ansible_host: TU_IP_AQUI
          ansible_user: root
```

### 3. Configurar variables

Editar `inventory/production/group_vars/all.yml`:

```yaml
# Dominios
lowcode_domain_base: "tudominio.com"
lowcode_domain_supabase: "supabase.tudominio.com"
lowcode_domain_n8n: "n8n.tudominio.com"
lowcode_domain_appsmith: "appsmith.tudominio.com"

# Email para Let's Encrypt
lowcode_letsencrypt_email: "admin@tudominio.com"
```

### 4. Generar secretos

```bash
chmod +x files/scripts/generate_secrets.sh
./files/scripts/generate_secrets.sh > secrets.txt
```

Copiar los valores generados a `inventory/production/group_vars/all/vault.yml`.

**Importante**: Generar las JWT keys de Supabase en:
https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys

### 5. Encriptar secretos con Ansible Vault

```bash
ansible-vault encrypt inventory/production/group_vars/all/vault.yml
```

Guardar la contrasena del vault de forma segura.

### 6. Desplegar

```bash
# Con Docker (Windows/macOS):
docker compose run --rm ansible playbooks/site.yml --ask-vault-pass

# Con virtualenv (Linux):
ansible-playbook playbooks/site.yml --ask-vault-pass

# O con archivo de password (ambos):
echo "tu_password" > .vault_pass
chmod 600 .vault_pass
docker compose run --rm ansible playbooks/site.yml
# o: ansible-playbook playbooks/site.yml
```

## Estructura del Proyecto

```
.
├── Dockerfile                  # Contenedor Ansible
├── docker-compose.yml          # Orquestacion Docker
├── docker-entrypoint.sh        # Script de entrada
├── ansible.cfg                 # Configuracion de Ansible
├── requirements.yml            # Dependencias de Galaxy
├── inventory/
│   └── production/
│       ├── hosts.yml           # Servidores
│       └── group_vars/
│           ├── all.yml         # Variables globales
│           └── all/
│               └── vault.yml   # Secretos (encriptados)
├── playbooks/
│   ├── site.yml                # Despliegue completo
│   ├── setup.yml               # Solo configuracion inicial
│   └── deploy.yml              # Solo servicios
├── roles/
│   ├── common/                 # Sistema base, UFW, paquetes
│   ├── nginx/                  # Reverse proxy + SSL
│   ├── redis/                  # Cache
│   ├── supabase/               # Backend
│   ├── appsmith/               # Low-code builder
│   └── n8n/                    # Workflows
└── files/
    └── scripts/
        └── generate_secrets.sh # Generador de secretos
```

## Playbooks Disponibles

| Playbook | Descripcion |
|----------|-------------|
| `site.yml` | Despliegue completo (recomendado) |
| `setup.yml` | Solo configuracion del sistema |
| `deploy.yml` | Solo despliegue de servicios |

## Tags Disponibles

```bash
# Por rol
ansible-playbook playbooks/site.yml --tags common
ansible-playbook playbooks/site.yml --tags docker
ansible-playbook playbooks/site.yml --tags supabase
ansible-playbook playbooks/site.yml --tags appsmith
ansible-playbook playbooks/site.yml --tags n8n
ansible-playbook playbooks/site.yml --tags nginx

# Especificos
ansible-playbook playbooks/site.yml --tags watermark  # Solo patch Appsmith
ansible-playbook playbooks/site.yml --tags ssl        # Solo certificados
ansible-playbook playbooks/site.yml --tags deploy     # Solo despliegue
```

## Configuracion

### Variables Principales (`all.yml`)

```yaml
# Servidor
lowcode_server_ip: "72.62.13.157"
lowcode_base_path: "/opt/lowcode-stack"
lowcode_timezone: "America/Argentina/Buenos_Aires"

# Dominios
lowcode_domain_base: "benabhi.xyz"
lowcode_domain_supabase: "supabase.{{ lowcode_domain_base }}"
lowcode_domain_n8n: "n8n.{{ lowcode_domain_base }}"
lowcode_domain_appsmith: "appsmith.{{ lowcode_domain_base }}"

# Versiones
lowcode_supabase_version: "latest"
lowcode_appsmith_version: "latest"
lowcode_n8n_version: "latest"
lowcode_redis_version: "7-alpine"

# Puertos internos
lowcode_supabase_api_port: 8000
lowcode_supabase_studio_port: 3000
lowcode_n8n_port: 5678
lowcode_appsmith_port: 8081
lowcode_redis_port: 6379
```

### Secretos (`vault.yml`)

```yaml
# Supabase
vault_supabase_postgres_password: "..."
vault_supabase_jwt_secret: "..."
vault_supabase_anon_key: "..."
vault_supabase_service_role_key: "..."
vault_supabase_dashboard_password: "..."

# n8n
vault_n8n_encryption_key: "..."

# Appsmith
vault_appsmith_encryption_password: "..."
vault_appsmith_encryption_salt: "..."

# Redis
vault_redis_password: "..."

# Nginx Basic Auth
vault_nginx_htpasswd_users:
  - username: "admin"
    password: "..."
```

## Patch de Watermark de Appsmith

El rol de Appsmith incluye un patch automatico para remover la marca de agua "Built on Appsmith" de la Community Edition.

**Importante**: Este patch NO es persistente. Se debe reaplicar despues de:
- Actualizar el contenedor
- Recrear el contenedor
- Reiniciar el contenedor

Para reaplicar manualmente:

```bash
ansible-playbook playbooks/site.yml --tags watermark --ask-vault-pass
```

O con el script incluido:

```bash
./roles/appsmith/files/patch_watermark.sh lowcode-appsmith
```

## SSL/HTTPS

Los certificados SSL se generan automaticamente con Let's Encrypt via Certbot.

- Los certificados se renuevan automaticamente (cron job diario)
- Para testing, usar `nginx_certbot_staging: true` en `all.yml`
- Certificados ubicados en `/etc/letsencrypt/live/`

## Basic Authentication

Supabase Studio esta protegido con HTTP Basic Auth por defecto.

Para cambiar las credenciales, editar `vault.yml`:

```yaml
vault_nginx_htpasswd_users:
  - username: "nuevo_usuario"
    password: "nueva_password"
```

Para deshabilitar, en `all.yml`:

```yaml
nginx_sites:
  - name: "supabase"
    basic_auth: false  # Cambiar a false
```

## Comandos Utiles

```bash
# Verificar sintaxis
ansible-playbook playbooks/site.yml --syntax-check

# Dry run (sin cambios)
ansible-playbook playbooks/site.yml --check --diff --ask-vault-pass

# Verbose output
ansible-playbook playbooks/site.yml -vvv --ask-vault-pass

# Limitar a un host
ansible-playbook playbooks/site.yml --limit lowcode-prod --ask-vault-pass
```

## Seguridad

- Firewall (UFW) configurado para solo permitir SSH, HTTP y HTTPS
- Todos los secretos encriptados con Ansible Vault
- SSL/TLS 1.2+ solamente
- HSTS habilitado
- Headers de seguridad configurados en Nginx
- Basic Auth para Supabase Studio

## Troubleshooting

### Certificados SSL no se generan

1. Verificar que los dominios apuntan al servidor (DNS)
2. Verificar que los puertos 80/443 estan abiertos
3. Usar `nginx_certbot_staging: true` para testing

### Appsmith watermark sigue visible

1. Limpiar cache del navegador (Ctrl+Shift+F5)
2. Verificar que el patch se aplico:
   ```bash
   docker exec lowcode-appsmith grep -c 'children:false&&' /opt/appsmith/editor/static/js/AppViewer.*.chunk.js
   ```
3. Reaplicar patch: `--tags watermark`

### Servicios no inician

1. Verificar logs de Docker:
   ```bash
   docker compose -f /opt/lowcode-stack/supabase/docker-compose.yml logs
   ```
2. Verificar espacio en disco
3. Verificar que Docker esta corriendo: `systemctl status docker`

## Licencia

MIT

## Autor

lowcode-stack
