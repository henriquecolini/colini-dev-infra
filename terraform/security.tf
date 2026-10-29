resource "oci_core_network_security_group" "vm" {
  compartment_id = oci_identity_compartment.colini_dev.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "colini-dev-vm-nsg"
}

locals {
  # One entry per inbound port this host needs. Web apps behind Coolify's
  # proxy and bots making outbound-only connections (Telegram/Discord) need
  # NOTHING added here. Add an entry only for a project that needs a raw,
  # non-proxied port — e.g. a game server:
  #
  #   minecraft = { min = 25565, max = 25565, protocol = "tcp", cidr = "0.0.0.0/0", desc = "Minecraft server" }
  #   some_udp_game = { min = 27015, max = 27015, protocol = "udp", cidr = "0.0.0.0/0", desc = "Some game server" }
  #
  # Then `tofu apply` and map the same port on the Coolify resource, bypassing
  # its HTTP proxy.
  ingress_rules = {
    ssh = {
      min = 22, max = 22, protocol = "tcp", cidr = var.admin_cidr, desc = "SSH"
    }
    http = {
      min = 80, max = 80, protocol = "tcp", cidr = "0.0.0.0/0", desc = "HTTP (Coolify proxy)"
    }
    https = {
      min = 443, max = 443, protocol = "tcp", cidr = "0.0.0.0/0", desc = "HTTPS (Coolify proxy)"
    }
    coolify_dashboard = {
      min = 8000, max = 8000, protocol = "tcp", cidr = var.admin_cidr, desc = "Coolify UI"
    }
    coolify_realtime = {
      min = 6001, max = 6001, protocol = "tcp", cidr = var.admin_cidr, desc = "Coolify realtime"
    }
    coolify_terminal = {
      min = 6002, max = 6002, protocol = "tcp", cidr = var.admin_cidr, desc = "Coolify web terminal"
    }
    dogbot_sftp = {
      min = 2222, max = 2222, protocol = "tcp", cidr = "0.0.0.0/0", desc = "dogbot SFTP (chat filesystem mounts)"
    }
  }

  tcp_ingress_rules = { for k, v in local.ingress_rules : k => v if v.protocol == "tcp" }
  udp_ingress_rules = { for k, v in local.ingress_rules : k => v if v.protocol == "udp" }
}

resource "oci_core_network_security_group_security_rule" "ingress_tcp" {
  for_each = local.tcp_ingress_rules

  network_security_group_id = oci_core_network_security_group.vm.id
  direction                 = "INGRESS"
  protocol                  = "6" # OCI wants the IANA protocol number as a string; 6 = TCP
  source                    = each.value.cidr
  source_type               = "CIDR_BLOCK"
  description               = each.value.desc

  tcp_options {
    destination_port_range {
      min = each.value.min
      max = each.value.max
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_udp" {
  for_each = local.udp_ingress_rules

  network_security_group_id = oci_core_network_security_group.vm.id
  direction                 = "INGRESS"
  protocol                  = "17" # 17 = UDP
  source                    = each.value.cidr
  source_type               = "CIDR_BLOCK"
  description               = each.value.desc

  udp_options {
    destination_port_range {
      min = each.value.min
      max = each.value.max
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_all" {
  network_security_group_id = oci_core_network_security_group.vm.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  description               = "all outbound"
}
