data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_arm" {
  compartment_id           = oci_identity_compartment.colini_dev.id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "vm" {
  compartment_id      = oci_identity_compartment.colini_dev.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard.A1.Flex"
  display_name        = "colini-dev-vm"

  # Full Always Free Ampere A1 allocation as of 2026 — Oracle halved this from
  # the older, still widely-cited 4 OCPU / 24GB figure. Re-verify the current
  # entitlement before changing these numbers.
  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = false # a RESERVED public IP is attached separately below, so it survives instance replacement
    nsg_ids          = [oci_core_network_security_group.vm.id]
    hostname_label   = "colini-dev"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 100 # leaves headroom under the 200GB total free block storage allocation
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile(
      "${path.module}/../cloud-init/coolify-bootstrap.yaml.tftpl", {}
    ))
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id] # don't force a rebuild every time Canonical ships a new image
  }
}

# Always Free VM.Standard.A1.Flex capacity is frequently exhausted tenancy-wide
# ("Out of host capacity" on apply). This is normal, not a config bug — just
# retry; Oracle replenishes capacity continuously and timing is unpredictable.

data "oci_core_vnic_attachments" "vm" {
  compartment_id = oci_identity_compartment.colini_dev.id
  instance_id    = oci_core_instance.vm.id
}

data "oci_core_private_ips" "vm" {
  vnic_id = data.oci_core_vnic_attachments.vm.vnic_attachments[0].vnic_id
}

resource "oci_core_public_ip" "vm" {
  compartment_id = oci_identity_compartment.colini_dev.id
  lifetime       = "RESERVED"
  # oci_core_vnic exposes an IP *address*, not the private IP object's OCID
  # that this resource actually wants — that OCID only comes from the
  # oci_core_private_ips list data source, filtered to the primary IP.
  private_ip_id = [for ip in data.oci_core_private_ips.vm.private_ips : ip.id if ip.is_primary][0]
  display_name  = "colini-dev-reserved-ip"

  # Unverified post-halving: confirm this still carries the "Always Free
  # eligible" badge in the Console after the first apply.
}
