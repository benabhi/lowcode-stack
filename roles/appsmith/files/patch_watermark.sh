#!/bin/bash
# ==============================================================================
# Appsmith Watermark Patch Script
# ==============================================================================
# This script removes the "Built on Appsmith" watermark from Community Edition.
# Run this script manually if the patch fails during Ansible deployment.
#
# Usage: ./patch_watermark.sh [container_name]
# ==============================================================================

set -e

CONTAINER_NAME="${1:-lowcode-appsmith}"
PATTERN='children:!W&&'
REPLACEMENT='children:false\&\&'
CHUNK_PATH="/opt/appsmith/editor/static/js"

echo "=========================================="
echo "Appsmith Watermark Patch Script"
echo "=========================================="
echo "Container: $CONTAINER_NAME"
echo ""

# Wait for container to be healthy
echo "[1/5] Waiting for Appsmith container to be healthy..."
while [ "$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_NAME 2>/dev/null)" != "healthy" ]; do
    echo "  Waiting..."
    sleep 5
done
echo "  Container is healthy!"

# Find chunk file
echo "[2/5] Finding AppViewer chunk file..."
CHUNK_FILE=$(docker exec $CONTAINER_NAME sh -c "ls $CHUNK_PATH/AppViewer.*.chunk.js 2>/dev/null | head -1")

if [ -z "$CHUNK_FILE" ]; then
    echo "ERROR: Could not find AppViewer chunk file"
    echo "  Path searched: $CHUNK_PATH/AppViewer.*.chunk.js"
    exit 1
fi
echo "  Found: $CHUNK_FILE"

# Check if already patched
echo "[3/5] Checking if patch is already applied..."
if docker exec $CONTAINER_NAME grep -q 'children:false&&' "$CHUNK_FILE"; then
    echo "  Appsmith is already patched. No action needed."
    echo ""
    echo "If you still see the watermark, clear your browser cache (Ctrl+Shift+F5)"
    exit 0
fi

# Apply patch
echo "[4/5] Applying patch..."
docker exec $CONTAINER_NAME perl -i -pe "s/$PATTERN/$REPLACEMENT/g" "$CHUNK_FILE"

# Verify
echo "[5/5] Verifying patch..."
if docker exec $CONTAINER_NAME grep -q 'children:false&&' "$CHUNK_FILE"; then
    echo ""
    echo "=========================================="
    echo "SUCCESS! Watermark patch applied."
    echo "=========================================="
    echo ""
    echo "IMPORTANT:"
    echo "- Refresh Appsmith in your browser (Ctrl+Shift+F5)"
    echo "- This patch is NOT persistent across container restarts"
    echo "- Re-run this script or the Ansible playbook after updates"
    echo ""
else
    echo ""
    echo "WARNING: Could not verify the patch was applied."
    echo "Please check manually:"
    echo "  docker exec $CONTAINER_NAME grep -c 'children:false&&' $CHUNK_FILE"
    exit 1
fi
