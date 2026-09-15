variable "region" {
  description = "OCI region to deploy into, e.g. us-ashburn-1"
  type        = string
}

variable "tenancy_ocid" {
  description = "OCID of the root tenancy. The colini-dev compartment is created directly under it."
  type        = string
}

variable "admin_cidr" {
  description = "CIDR allowed to reach SSH and the Coolify dashboard/realtime/terminal ports. Prefer your own IP as a /32 over 0.0.0.0/0."
  type        = string
}

variable "ssh_public_key" {
  description = "Public key installed on the VM for SSH access (contents of e.g. ~/.ssh/id_ed25519.pub)"
  type        = string
}
