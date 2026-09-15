# Runbook

Day-2 operations for the colini-dev host.

## SSH access

```
ssh ubuntu@<reserved-ip>   # or the appropriate default user for the image in use
```

Key-based only, from `var.admin_cidr` per the NSG rules in `terraform/security.tf`.

## Adding a new project

The boundary to keep in mind: **this repo (Terraform) owns infrastructure — the VM, network, firewall. Coolify's dashboard owns everything running on the VM.** Don't try to model Coolify's per-app config in HCL.

Three cases:

- **Web app** — register the repo in Coolify (GitHub App), pick a build pack (Dockerfile is preferred — see `docs/architecture.md`'s decision log on native ARM builds), set a domain. HTTPS is automatic. No Terraform change needed.
- **Telegram/Discord bot** — register the repo in Coolify as an Application with **no domain/FQDN set**; it just runs the container. No NSG change needed since these make outbound-only connections. If it needs storage, reuse the shared Postgres/Redis resource (see below) rather than provisioning a new one.
- **Game server or anything needing a raw TCP/UDP port** — add one entry to `local.ingress_rules` in `terraform/security.tf`, `tofu apply`, then map the same port on the Coolify resource, bypassing its HTTP proxy. This is the one case that touches Terraform.

## Shared database discipline

12GB total RAM doesn't stretch far if every project gets its own database container. Convention:

- **Postgres**: one shared Coolify-managed Postgres resource for the whole host. New project needs Postgres → `CREATE DATABASE <project>` inside the existing instance, not a new container.
- **Redis**: same pattern once a project first needs it — one shared instance, namespaced per project (key prefix or DB index), not one container per project.

## Resource limits

Set CPU/memory limits on each Coolify resource (a built-in Coolify feature) so one runaway process — a bot stuck in a loop, a game server under load — can't starve everything else on the box. Do this from the first non-trivial project onward, not reactively after something breaks.

## Rotating secrets

App-level secrets (`NEXTAUTH_SECRET`, OAuth client secrets, DB passwords) live entirely inside Coolify's own encrypted env var store — rotate them there per-project, redeploy. They never touch this repo.

Infra-level secrets:
- OCI API key (`~/.oci/`): regenerate via Console → My Profile → API Keys, update the local config, no Terraform change needed.
- Customer Secret Key (state backend auth): regenerate via Console → My Profile → Customer Secret Keys, update wherever `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` are exported locally.

## Patching the OS

Standard `apt update && apt upgrade` on the VM. Coolify itself has its own update mechanism through its dashboard — check there periodically too, since it's an actively-developed piece of software with its own release cadence.

## Known quirks

- **"Out of host capacity"** on a `tofu apply` that touches `oci_core_instance.vm` is a known Always Free A1 shape issue (capacity pool is tenancy-wide and frequently exhausted, worse since the 2026 entitlement halving) — not a config bug. Retry.
- **Don't assume the old 4 OCPU/24GB Always Free figure** — it hasn't been true since 2026. Re-check `docs.oracle.com`'s Always Free Resources page before changing `shape_config` in `terraform/compute.tf`.
- OCI's OS-level firewall (`ufw` on Ubuntu images) is on by default in addition to the NSG — if a port is open in `terraform/security.tf` but still unreachable, check `ufw status` on the VM.
