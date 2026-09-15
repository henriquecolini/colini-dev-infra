# Bootstrap

One-time manual steps required before the first `tofu apply` can run. These exist outside Terraform on purpose — mostly because they create the very thing Terraform's state depends on (the state bucket), which is a chicken-and-egg problem no amount of HCL solves cleanly.

## 1. Local OCI CLI / API auth

```
oci setup config
```

Walks you through generating an RSA API signing key pair and writes `~/.oci/config`. This is per-machine, never committed to this repo.

## 2. Create the Terraform state bucket

```
oci os bucket create --compartment-id <tenancy-or-compartment-ocid> --name colini-dev-tfstate --versioning Enabled
oci os ns get   # prints your Object Storage namespace — needed for the backend endpoint URL
```

Versioning must be enabled for `use_lockfile` (native OpenTofu state locking) to work.

## 3. Generate a Customer Secret Key

Console → Profile menu → **My Profile** → **Customer Secret Keys** → Generate. This is a separate credential from your OCI API key, used only for the S3-compatible Object Storage endpoint that `terraform/backend.tf` talks to. The secret is shown once — put it in a password manager, then export it locally when you need to run Terraform:

```
export AWS_ACCESS_KEY_ID=<the access key>
export AWS_SECRET_ACCESS_KEY=<the secret key>
```

## 4. Fill in the backend and variables

- Edit the placeholders in `terraform/backend.tf` (region, Object Storage namespace).
- Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` (gitignored) and fill in your tenancy OCID, region, admin CIDR, and SSH public key.

## 5. Init, plan, apply

```
cd terraform
tofu init
tofu plan     # read this output before applying, every time
tofu apply
```

If `apply` fails with an "Out of host capacity" error on the instance, that's normal for the Always Free A1 shape (see `docs/architecture.md`) — just retry.

## 6. Verify the state lock actually works

Since OpenTofu's S3-backend `use_lockfile` against OCI's S3-compatible endpoint isn't independently confirmed anywhere in the research behind this repo, check it once: run `tofu plan` in two terminals back to back and confirm the second one blocks with a lock error rather than racing the first. If it misbehaves, drop `use_lockfile` from `backend.tf` — as a single-operator project, the risk of skipping locking entirely is low.

## 7. Complete Coolify's first-run setup

SSH into the new VM, confirm `docker ps` shows Coolify's containers healthy, then open `http://<reserved-ip>:8000` in a browser and complete the setup wizard there. Don't pre-seed a root password through cloud-init — it would sit in plaintext in both OCI instance metadata and Terraform state.
