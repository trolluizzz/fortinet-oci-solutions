resource "oci_core_instance" "FortiGate-B" {
  depends_on          = [oci_core_subnet.hb_subnet]
  availability_domain = lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_b - 1], "name")
  compartment_id      = var.compartment_ocid
  display_name        = "FortiGate-B"
  shape               = var.instance_shape
  // Uncomment and addapt if you are yousing newer instance types like VM.Standard.E3.Flex
  #  shape_config {
  #    memory_in_gbs = "16"
  #    ocpus         = "4"
  #  }


  create_vnic_details {
    #subnet_id        = oci_core_subnet.mgmt_subnet.id
    #COMPROBAR SI OCUPO EL COMANDO ANTERIOR O LLAMAR EL DATA
    ########################################
    subnet_id = data.oci_core_subnet.mgmt_subnet.id
    ########################################
    display_name     = "FortiGate-B"
    assign_public_ip = true
    hostname_label   = "vmb"
    private_ip       = var.mgmt_private_ip_primary_b
  }

  source_details {
    source_type = "image"
    source_id   = var.vm_image_ocid

    //for PIC image: source_id   = var.vm_image_ocid

    # Apply this to set the size of the boot volume that's created for this instance.
    # Otherwise, the default boot volume size of the image is used.
    # This should only be specified when source_type is set to "image".
    #boot_volume_size_in_gbs = "60"
  }

  # Apply the following flag only if you wish to preserve the attached boot volume upon destroying this instance
  # Setting this and destroying the instance will result in a boot volume that should be managed outside of this config.
  # When changing this value, make sure to run 'terraform apply' so that it takes effect before the resource is destroyed.
  #preserve_boot_volume = true


  //required for metadata setup via cloud-init
  metadata = {
    // ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(data.template_file.FortiGate-B_userdata.rendered)
  }

  timeouts {
    create = "60m"
  }
}

resource "oci_core_vnic_attachment" "vnic_attach_untrust_b" {
  depends_on   = [oci_core_instance.FortiGate-B]
  instance_id  = oci_core_instance.FortiGate-B.id
  display_name = "vnic_untrust_b"

  create_vnic_details {
    subnet_id              = oci_core_subnet.untrust_subnet.id
    display_name           = "vnic_untrust_b"
    assign_public_ip       = false
    skip_source_dest_check = false
    private_ip             = var.untrust_private_ip_primary_b
  }
}


resource "oci_core_vnic_attachment" "vnic_attach_trust_b" {
  depends_on   = [oci_core_vnic_attachment.vnic_attach_untrust_b]
  instance_id  = oci_core_instance.FortiGate-B.id
  display_name = "vnic_trust"

  create_vnic_details {
    subnet_id              = oci_core_subnet.trust_subnet.id
    display_name           = "vnic_trust_b"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.trust_private_ip_primary_b
  }
}


resource "oci_core_vnic_attachment" "vnic_attach_hb_b" {
  depends_on   = [oci_core_vnic_attachment.vnic_attach_trust_b]
  instance_id  = oci_core_instance.FortiGate-B.id
  display_name = "vnic_hb_b"

  create_vnic_details {
    subnet_id              = oci_core_subnet.hb_subnet.id
    display_name           = "vnic_hb_b"
    assign_public_ip       = false
    skip_source_dest_check = true
    private_ip             = var.hb_private_ip_primary_b
  }
}


data "template_file" "FortiGate-B_userdata" {
  template = file(var.bootstrap_FortiGate-B)

  vars = {
    mgmt_ip                          = var.mgmt_private_ip_primary_b
    mgmt_ip_mask                     = "255.255.255.0"
    untrust_ip                       = var.untrust_private_ip_primary_b
    untrust_ip_mask                  = "255.255.255.0"
    trust_ip                         = var.trust_private_ip_primary_b
    trust_ip_mask                    = "255.255.255.0"
    hb_ip                            = var.hb_private_ip_primary_b
    hb_ip_mask                       = "255.255.255.0"
    hb_peer_ip                       = var.hb_private_ip_primary_a
    untrust_floating_private_ip      = var.untrust_floating_private_ip
    untrust_floating_private_ip_mask = "255.255.255.0"
    trust_floating_private_ip        = var.trust_floating_private_ip
    trust_floating_private_ip_mask   = "255.255.255.0"
    untrust_subnet_gw                = var.untrust_subnet_gateway
    vcn_cidr                         = var.vcn_cidr
    trust_subnet_gw                  = var.trust_subnet_gateway
    mgmt_subnet_gw                   = var.mgmt_subnet_gateway

    tenancy_ocid = var.tenancy_ocid
    //oci_user_ocid = var.oci_user_ocid
    compartment_ocid = var.compartment_ocid

  }
}
