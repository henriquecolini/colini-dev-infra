resource "oci_core_vcn" "main" {
  compartment_id = oci_identity_compartment.colini_dev.id
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "colini-dev-vcn"
  dns_label      = "colinidev"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = oci_identity_compartment.colini_dev.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "colini-dev-igw"
  enabled        = true
}

resource "oci_core_route_table" "public" {
  compartment_id = oci_identity_compartment.colini_dev.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "colini-dev-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = oci_identity_compartment.colini_dev.id
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = "10.0.0.0/24"
  display_name               = "colini-dev-public-subnet"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  prohibit_public_ip_on_vnic = false

  # No security_list_ids given on purpose: this falls back to the VCN's
  # auto-created default security list, which (unlike a Console-wizard VCN)
  # ships empty when created via Terraform. All actual ingress rules live on
  # the instance-level NSG in security.tf instead. Confirm the default list
  # is still empty after the first apply — OCI ORs subnet security lists with
  # instance NSGs, so a non-empty default list would silently widen access.
}
