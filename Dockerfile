# ==============================================================================
# Ansible Control Node Container
# ==============================================================================
# Este contenedor proporciona un entorno completo para ejecutar Ansible
# y desplegar el lowcode-stack en servidores Ubuntu 24.04 LTS.
#
# Build:  docker build -t lowcode-ansible .
# Run:    docker run -it --rm -v ~/.ssh:/root/.ssh:ro lowcode-ansible
# ==============================================================================

FROM python:3.12-slim-bookworm

LABEL maintainer="lowcode-stack"
LABEL description="Ansible control node for lowcode-stack deployment"
LABEL version="1.0"

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_FORCE_COLOR=True
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    git \
    sshpass \
    curl \
    jq \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalar Ansible y dependencias Python
RUN pip install --no-cache-dir \
    ansible \
    jmespath \
    netaddr

# Crear directorio de trabajo
WORKDIR /ansible

# Copiar requirements primero (para cache de Docker)
COPY requirements.yml .

# Instalar roles y colecciones de Galaxy
RUN ansible-galaxy install -r requirements.yml

# Copiar el resto del proyecto
COPY . .

# Crear directorio para SSH keys
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Script de entrada (convertir CRLF a LF por si viene de Windows)
COPY docker-entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["--help"]
