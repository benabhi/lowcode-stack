#!/bin/bash
# ==============================================================================
# Docker Entrypoint para Ansible Control Node
# ==============================================================================

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Copiar SSH keys con permisos correctos (necesario en Windows)
if [ -d "/tmp/.ssh-host" ]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    # Copiar solo archivos, no el config si tiene problemas
    for file in /tmp/.ssh-host/id_* /tmp/.ssh-host/*.pem; do
        if [ -f "$file" ]; then
            cp "$file" /root/.ssh/
        fi
    done
    # Copiar known_hosts si existe
    if [ -f "/tmp/.ssh-host/known_hosts" ]; then
        cp /tmp/.ssh-host/known_hosts /root/.ssh/
    fi
    # Fijar permisos
    chmod 600 /root/.ssh/* 2>/dev/null || true
    chmod 644 /root/.ssh/*.pub 2>/dev/null || true
fi

# Mostrar banner
echo -e "${CYAN}"
echo "=============================================="
echo "  LOW-CODE STACK - Ansible Control Node"
echo "=============================================="
echo -e "${NC}"

# Verificar si hay argumentos
if [ "$1" = "--help" ] || [ -z "$1" ]; then
    echo -e "${GREEN}Uso:${NC}"
    echo ""
    echo "  Despliegue completo:"
    echo "    docker compose run --rm ansible playbooks/site.yml --ask-vault-pass"
    echo ""
    echo "  Solo setup del sistema:"
    echo "    docker compose run --rm ansible playbooks/setup.yml"
    echo ""
    echo "  Solo servicios:"
    echo "    docker compose run --rm ansible playbooks/deploy.yml --ask-vault-pass"
    echo ""
    echo "  Verificar conexion:"
    echo "    docker compose run --rm ansible all -m ping"
    echo ""
    echo "  Dry run:"
    echo "    docker compose run --rm ansible playbooks/site.yml --check --diff"
    echo ""
    echo "  Shell interactivo:"
    echo "    docker compose run --rm --entrypoint bash ansible"
    echo ""
    echo -e "${YELLOW}Playbooks disponibles:${NC}"
    echo "  - playbooks/site.yml    (despliegue completo)"
    echo "  - playbooks/setup.yml   (solo configuracion del sistema)"
    echo "  - playbooks/deploy.yml  (solo servicios)"
    echo ""
    echo -e "${YELLOW}Tags disponibles:${NC}"
    echo "  --tags common,docker,redis,supabase,appsmith,n8n,nginx,watermark"
    echo ""
    exit 0
fi

# Si el primer argumento es un playbook o comando ansible
if [[ "$1" == playbooks/* ]] || [[ "$1" == *.yml ]]; then
    exec ansible-playbook "$@"
elif [[ "$1" == all ]] || [[ "$1" == lowcode* ]]; then
    exec ansible -i inventory/production/hosts.yml "$@"
else
    exec "$@"
fi
