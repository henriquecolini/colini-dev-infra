# Architecture

## Topology

```
Internet
   │
   ├── DNS: *.colini.dev A records → reserved public IP
   │
   ▼
OCI VCN (colini-dev-vcn, 10.0.0.0/16)
   └── public subnet (10.0.0.0/24)
        └── colini-dev-vm  (VM.Standard.A1.Flex, 2 OCPU / 12GB RAM, Ubuntu 24.04 ARM64)
             ├── NSG: colini-dev-vm-nsg — 22/80/443 open, 8000/6001/6002 admin-only
             ├── Docker
             └── Coolify (self-hosted PaaS)
                  ├── built-in reverse proxy (Caddy/Traefik) — auto HTTPS for every web app
                  ├── shared Postgres resource — one instance, one database per project
                  ├── shared Redis resource (added when first needed)
                  └── per-project resources — planifik, and whatever comes next
                       (web apps, Telegram/Discord bots, small game servers)
```

One VM hosts everything. This isn't an accident of laziness — it's the whole point: the Always Free ARM entitlement (2 OCPU / 12GB RAM / 200GB storage, see the note below) is a single shared pool, and Coolify exists specifically so that pool can be subdivided among many small things without hand-managing each one.

## Resource inventory (managed by `terraform/`)

| Resource | Purpose |
|---|---|
| `oci_identity_compartment.colini_dev` | Isolates everything below from the rest of the tenancy |
| `oci_core_vcn.main` + subnet/IGW/route table | Networking |
| `oci_core_network_security_group.vm` | Perimeter firewall — see `terraform/security.tf` for the extensible port map |
| `oci_core_instance.vm` | The VM itself |
| `oci_core_public_ip.vm` | Reserved public IP, survives instance replacement |

Everything *inside* the VM (Coolify itself, and every project deployed through it) is **not** Terraform-managed — that's Coolify's job, operated through its dashboard. See `docs/runbook.md` for the boundary between "change Terraform" and "change Coolify."

## Decision log

- **Always Free ARM entitlement is 2 OCPU / 12GB RAM / 200GB storage**, not the commonly-cited 4 OCPU/24GB — Oracle halved it in 2026. Sized the VM to the full current entitlement.
- **Coolify**, not CapRover/Dokku/a DIY GitHub-Actions-and-SSH pipeline — official ARM64 support, an official OCI setup guide, a real dashboard for "register a repo and it deploys," and it handles non-HTTP workloads (bots, game servers) as a first-class case, not just websites.
- **OpenTofu**, not Terraform proper — same `oracle/oci` provider, avoids Terraform's BSL license, no practical downside at this scale.
- **One shared Postgres/Redis instance**, not one database container per project — 12GB total RAM doesn't stretch far if every small project gets its own DB container.
- **Coolify builds from source directly on the ARM VM** for planifik (and by default for future projects) rather than pulling prebuilt images from a registry — simpler, natively ARM (no slow QEMU cross-builds), no multi-arch CI to maintain.
