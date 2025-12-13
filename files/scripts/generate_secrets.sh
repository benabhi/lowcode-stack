#!/bin/bash
# ==============================================================================
# Secret Generation Script for lowcode_stack
# ==============================================================================
# This script generates secure random secrets for all services.
#
# Usage:
#   ./generate_secrets.sh
#   ./generate_secrets.sh > secrets.txt
#
# After generating, copy the values to:
#   inventory/production/group_vars/all/vault.yml
#
# Then encrypt with:
#   ansible-vault encrypt inventory/production/group_vars/all/vault.yml
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to generate random alphanumeric string
generate_random() {
    local length=${1:-32}
    openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

# Function to generate random hex string
generate_hex() {
    local length=${1:-32}
    openssl rand -hex "$((length / 2))"
}

# Function to generate base64 string
generate_base64() {
    local bytes=${1:-32}
    openssl rand -base64 "$bytes"
}

echo -e "${GREEN}=============================================="
echo "LOWCODE_STACK SECRET GENERATOR"
echo -e "==============================================${NC}"
echo ""
echo "Generated on: $(date)"
echo ""
echo -e "${YELLOW}Copy these values to: inventory/production/group_vars/all/vault.yml${NC}"
echo -e "${YELLOW}Then run: ansible-vault encrypt inventory/production/group_vars/all/vault.yml${NC}"
echo ""
echo "=============================================="
echo ""

# Supabase secrets
echo "# =============================================="
echo "# SUPABASE SECRETS"
echo "# =============================================="
POSTGRES_PASSWORD=$(generate_random 32)
JWT_SECRET=$(generate_base64 32)
DASHBOARD_PASSWORD=$(generate_random 16)

echo "vault_supabase_postgres_password: \"${POSTGRES_PASSWORD}\""
echo "vault_supabase_jwt_secret: \"${JWT_SECRET}\""
echo ""
echo "# IMPORTANT: Generate these JWT keys at:"
echo "# https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys"
echo "# Use the JWT_SECRET above when generating"
echo "vault_supabase_anon_key: \"GENERATE_AT_SUPABASE_DOCS\""
echo "vault_supabase_service_role_key: \"GENERATE_AT_SUPABASE_DOCS\""
echo ""
echo "vault_supabase_dashboard_username: \"admin\""
echo "vault_supabase_dashboard_password: \"${DASHBOARD_PASSWORD}\""
echo ""

# n8n secrets
echo "# =============================================="
echo "# N8N SECRETS"
echo "# =============================================="
N8N_ENCRYPTION_KEY=$(generate_hex 32)
N8N_PASSWORD=$(generate_random 16)

echo "vault_n8n_encryption_key: \"${N8N_ENCRYPTION_KEY}\""
echo "vault_n8n_basic_auth_user: \"admin\""
echo "vault_n8n_basic_auth_password: \"${N8N_PASSWORD}\""
echo ""

# Appsmith secrets
echo "# =============================================="
echo "# APPSMITH SECRETS"
echo "# =============================================="
APPSMITH_ENCRYPTION=$(generate_random 32)
APPSMITH_SALT=$(generate_random 32)

echo "vault_appsmith_encryption_password: \"${APPSMITH_ENCRYPTION}\""
echo "vault_appsmith_encryption_salt: \"${APPSMITH_SALT}\""
echo ""

# Redis secrets
echo "# =============================================="
echo "# REDIS SECRETS"
echo "# =============================================="
REDIS_PASSWORD=$(generate_random 32)

echo "vault_redis_password: \"${REDIS_PASSWORD}\""
echo ""

# Nginx Basic Auth
echo "# =============================================="
echo "# NGINX BASIC AUTH"
echo "# =============================================="
HTPASSWD_PASSWORD=$(generate_random 16)

echo "vault_nginx_htpasswd_users:"
echo "  - username: \"admin\""
echo "    password: \"${HTPASSWD_PASSWORD}\""
echo ""

# SMTP (placeholder)
echo "# =============================================="
echo "# SMTP (Configure if needed)"
echo "# =============================================="
echo "vault_smtp_host: \"smtp.example.com\""
echo "vault_smtp_port: 587"
echo "vault_smtp_user: \"noreply@example.com\""
echo "vault_smtp_password: \"CHANGE_ME\""
echo "vault_smtp_from: \"noreply@example.com\""
echo ""

echo "=============================================="
echo ""
echo -e "${GREEN}Secrets generated successfully!${NC}"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. Copy the output above to: inventory/production/group_vars/all/vault.yml"
echo "2. Generate Supabase JWT keys at the URL mentioned above"
echo "3. Encrypt the vault file:"
echo "   ansible-vault encrypt inventory/production/group_vars/all/vault.yml"
echo "4. Save the vault password securely"
echo ""
