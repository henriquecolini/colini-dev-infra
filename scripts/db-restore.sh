#!/usr/bin/env bash
# Run on the NEW VM during the planifik cutover (see docs/migration.md).
# Restores a dump produced by db-dump.sh into the target database. Only
# start/restart the app container AFTER this completes, so
# `prisma migrate deploy` sees the already-applied _prisma_migrations table
# and no-ops instead of running fresh migrations against an empty schema.
set -euo pipefail

: "${PGHOST:?set PGHOST}"
: "${PGUSER:?set PGUSER}"
: "${PGDATABASE:?set PGDATABASE}"
DUMP="${1:?usage: db-restore.sh <dump-file>}"

pg_restore -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" --clean --if-exists -1 "$DUMP"
echo "Restored $DUMP into $PGDATABASE"
