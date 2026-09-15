#!/usr/bin/env bash
# Run on the OLD VM during the planifik cutover (see docs/migration.md).
# Dumps the database in custom format, including Prisma's _prisma_migrations
# table, so pg_restore on the new side leaves `prisma migrate deploy` seeing a
# schema it recognizes as already fully applied.
set -euo pipefail

: "${PGHOST:=localhost}"
: "${PGUSER:?set PGUSER}"
: "${PGDATABASE:?set PGDATABASE}"
OUT="${1:-planifik-$(date +%Y%m%d%H%M%S).dump}"

pg_dump -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -Fc -f "$OUT"
echo "Wrote $OUT"
