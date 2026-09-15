# A dedicated compartment isolates every resource this repo manages from the
# rest of the tenancy. One compartment for the whole host, shared by every
# project deployed on it — per-project compartments would be over-isolation
# for a single-operator box.
resource "oci_identity_compartment" "colini_dev" {
  compartment_id = var.tenancy_ocid
  name           = "colini-dev"
  description    = "Shared host for colini.dev personal projects: websites, bots, small game servers"
  enable_delete  = true
}
