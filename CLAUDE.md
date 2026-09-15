# CLAUDE.md

## What this repo is

OpenTofu-managed OCI infrastructure for one Always Free ARM VM (`VM.Standard.A1.Flex`, 2 OCPU / 12GB RAM) running [Coolify](https://coolify.io), a self-hosted PaaS. This is a **general-purpose personal platform** — web apps, Telegram/Discord bots, small game servers, whatever comes up — not a single-website repo. planifik (github.com/henriquecolini/planifik) is the first project migrated onto it.

**This repo owns infrastructure only.** The VM, network, firewall — that's Terraform's job. Everything running *on* the VM (Coolify itself, and every project deployed through it: build config, domains, env vars, databases) is owned by Coolify's own dashboard, not by HCL in this repo. Don't try to model Coolify's per-app state here.

See `docs/architecture.md` for the full topology and the reasoning behind the major decisions (Coolify vs. alternatives, OpenTofu vs. Terraform, shared-database convention).

## Running Terraform/OpenTofu

```
cd terraform
tofu plan     # ALWAYS read this before applying
tofu apply
```

Requires: `~/.oci/config` (local, per-machine, set up via `oci setup config` — never repo-managed) for the provider, and `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` env vars (an OCI Customer Secret Key, not the OCI API key) for the remote state backend. See `docs/bootstrap.md` for first-time setup.

**Never run `tofu apply` without reading the `plan` output first.** This manages real, billable-if-misconfigured cloud resources.

## Adding a new project

Not a Terraform operation in the common case — see `docs/runbook.md` for the three cases (web app / bot / raw-port service) and exactly what does and doesn't touch this repo.

## Secrets — where each kind lives

- OCI API key → `~/.oci/` on whatever machine runs Terraform. Never in this repo.
- Customer Secret Key (state backend auth) → a password manager, exported as env vars when needed. Never in this repo.
- App-level secrets (DB passwords, OAuth client secrets, etc.) → Coolify's own encrypted env var store, set per-project through its dashboard. Never in this repo.

## Never do this

- Never commit `*.tfvars` (only `terraform.tfvars.example`), `.terraform/`, or any `*.tfstate*` — `.gitignore` covers these, don't work around it.
- Never hardcode an OCID, secret, or password into a `.tf` file.
- Never assume the Always Free entitlement is 4 OCPU/24GB — Oracle halved it to 2 OCPU/12GB in 2026, and it could change again. Re-check `docs.oracle.com`'s Always Free Resources page before touching `shape_config` in `terraform/compute.tf`.
- Never treat an "Out of host capacity" error on `tofu apply` as a config bug — it's a known Always Free A1 capacity quirk (see `docs/runbook.md`). Retry instead of debugging the HCL.
