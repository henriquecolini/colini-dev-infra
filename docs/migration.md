# Migration: planifik cutover to the new VM

This is a one-time procedure for moving planifik from the old, unmanaged x86_64 VM onto the new Terraform+Coolify host. Kept here as a record even after it's done, in case the same pattern is useful for a future migration.

## 1. Stand up the new VM in parallel

`tofu apply` (see `docs/bootstrap.md` if this is the very first apply). The old VM keeps serving `planifik.colini.dev` throughout — nothing about it changes yet. Wait for cloud-init to finish, SSH in, confirm `docker ps` shows Coolify's containers healthy, complete Coolify's first-run wizard.

## 2. Register planifik in Coolify

- Connect the GitHub App to `henriquecolini/planifik`.
- Create the shared Postgres resource (first project to need one — see `docs/runbook.md`) plus a `planifik` database inside it.
- Configure the app: Dockerfile build pack, env vars `DATABASE_URL`, `NEXTAUTH_SECRET`, `NEXTAUTH_URL=https://planifik.colini.dev`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`.

## 3. Test before touching DNS

Add a temporary staging subdomain (e.g. `planifik-new.colini.dev`) pointed at the new reserved IP, so Coolify's proxy can issue a real Let's Encrypt cert and Google OAuth's callback flow (origin-sensitive) can be fully exercised. `/etc/hosts` overrides alone aren't sufficient for this — HTTPS cert issuance needs the domain to actually resolve.

## 4. Data migration (brief write-freeze)

On the **old** VM:
```
PGUSER=<user> PGDATABASE=<db> ../colini-dev/scripts/db-dump.sh planifik.dump
scp planifik.dump <new-vm>:~
```

On the **new** VM, into the Coolify-managed Postgres:
```
PGHOST=<coolify-postgres-host> PGUSER=<user> PGDATABASE=planifik ../colini-dev/scripts/db-restore.sh planifik.dump
```

Only start/restart the planifik app container **after** the restore completes — `start.sh` runs `prisma migrate deploy`, which needs to see the already-applied `_prisma_migrations` table so it no-ops instead of running fresh migrations against an empty schema.

## 5. Flip DNS

Point the `planifik.colini.dev` A record at the new reserved public IP. Wait for propagation, then re-verify login (Google OAuth), core app flows, and cert issuance for the real domain.

## 6. Decommission the old VM

After a confidence window (a day or two of clean traffic on the new VM), terminate the old x86 instance via the OCI Console. It was never Terraform-managed, so there's no code to update — it's just deleted once superseded.
