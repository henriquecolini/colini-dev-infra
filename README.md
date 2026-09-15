# colini-dev

Infrastructure-as-code for [colini.dev](https://colini.dev)'s personal hosting: one OCI Always Free ARM VM, provisioned with [OpenTofu](https://opentofu.org), running [Coolify](https://coolify.io) as a general-purpose deploy platform for web apps, bots, and small game servers.

This replaces a previous setup: one paid x86_64 VM, hand-configured over SSH with no automation, no documentation, and no path to hosting a second project without repeating the whole manual process by memory.

## Layout

- `terraform/` — OCI infrastructure (network, firewall, the VM itself) via the `oracle/oci` provider
- `cloud-init/` — first-boot provisioning (Docker + Coolify install)
- `docs/` — architecture, one-time bootstrap steps, day-2 runbook, and the planifik migration record
- `scripts/` — Postgres dump/restore helpers used during the planifik cutover

## Getting started

See [`docs/bootstrap.md`](docs/bootstrap.md) for the one-time setup (OCI CLI auth, Terraform state bucket, secrets), then [`docs/runbook.md`](docs/runbook.md) for day-to-day operations, including how to add a new project.

For the reasoning behind the major decisions here (why Coolify, why OpenTofu, why one shared Postgres instance), see [`docs/architecture.md`](docs/architecture.md).
