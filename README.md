# Low-Code Stack - Ansible Deployment

Coleccion profesional de Ansible para desplegar un stack completo de desarrollo low-code/no-code en Ubuntu 24.04 LTS.

## Servicios Incluidos

- **Supabase** - Backend as a Service (PostgreSQL, Auth, Storage, Realtime)
- **Appsmith** - Constructor de aplicaciones low-code (con patch de watermark)
- **n8n** - Automatizacion de workflows
- **Redis** - Cache para n8n
- **Nginx** - Reverse proxy con SSL (Let's Encrypt)

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
    ├── redis/                  # Cache
    ├── supabase/               # Backend
    ├── appsmith/               # Low-code builder
    ├── n8n/                    # Workflows
    └── nginx/                  # Reverse proxy + SSL
```

## Comandos Utiles

```bash
# Verificar conexion
docker compose run --rm ansible all -m ping --ask-pass

# Despliegue completo
docker compose run --rm ansible playbooks/site.yml --ask-pass

# Solo servicios (servidor ya configurado)
docker compose run --rm ansible playbooks/deploy.yml --ask-pass

# Dry run (sin cambios)
docker compose run --rm ansible playbooks/site.yml --check --diff --ask-pass

# Solo un servicio
docker compose run --rm ansible playbooks/site.yml --tags supabase --ask-pass

# Reaplicar patch de watermark
docker compose run --rm ansible playbooks/site.yml --tags watermark --ask-pass

# Shell interactivo
docker compose run --rm --entrypoint bash ansible
```

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
