#!/bin/bash

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔄 Creating backup..."

# Backup PostgreSQL
docker-compose exec postgres pg_dump -U headscale headscale > "$BACKUP_DIR/headscale.sql"

# Backup Headscale data
cp -r data/headscale "$BACKUP_DIR/"

# Backup configurations
cp -r config "$BACKUP_DIR/"

echo "✅ Backup completed: $BACKUP_DIR"