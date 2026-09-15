output "public_ip" {
  description = "Reserved public IP of the VM — point DNS records at this"
  value       = oci_core_public_ip.vm.ip_address
}

output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.vm.id
}

output "compartment_id" {
  description = "OCID of the colini-dev compartment"
  value       = oci_identity_compartment.colini_dev.id
}
