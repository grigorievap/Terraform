terraform {
	required_providers {
		proxmox = {
			source  = "telmate/proxmox"
			version = "2.9.6"
		}
	}
}

provider "proxmox" {
	# (Optional; defaults to false) Enable debug logging, see the section below for logging details.
	pm_log_enable = true
	# (Optional; defaults to "terraform-plugin-proxmox.log") If logging is enabled, the log file the provider will write logs to.
	pm_log_file = "terraform-plugin-proxmox.log"
	# (Optional; defaults to false) Enable verbose output in proxmox-api-go
	pm_debug = true
	# (Optional) A map of log sources and levels.
	pm_log_levels = {
		_default = "debug"
		# To silence and any stdout/stderr from sub libraries (proxmox-api-go), remove or comment out _capturelog.
		_capturelog = ""
	}
	# (Required; or use environment variable PM_API_URL) This is the target Proxmox API endpoint. Add /api2/json at the end for the API
	pm_api_url = "https://name:8006/api2/json"
	# (Optional; or use environment variable PM_API_TOKEN_ID) This is an API token you have previously created for a specific user.
	pm_api_token_id = ""
	# (Optional; or use environment variable PM_API_TOKEN_SECRET) This uuid is only available when the token was initially created.
	pm_api_token_secret = ""
	# (Optional) Disable TLS verification while connecting to the proxmox server.
	#pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "test" {
	# Кол-во машинок, которые создаем. 0 - удалит все машинки или не создаст
	count = 3
	# The ID of the VM in Proxmox. The default value of 0 indicates it should use the next available ID in the sequence. (count.index = 0, т.е. 1 машинка будет с индексом 1 и т.д.)
	vmid = "${1000 + count.index + 1}"
	# Required The name of the VM within Proxmox.
	name = "TEST-VM-${count.index + 1}"
	# Required The name of the Proxmox Node on which to place the VM
	target_node = var.proxmox_host
	# The base VM from which to clone to create the new VM. Note that clone is mutually exclussive with pxe and iso modes
	clone = var.template_name
	# Set to 1 to enable the QEMU Guest Agent. Note, you must run the qemu-guest-agent daemon in the quest for this to have any effect.
	agent = 1
	# Which provisioning method to use, based on the OS type. Options: ubuntu, centos, cloud-init.
	os_type = "cloud-init"
	# The number of CPU cores per CPU socket to allocate to the VM.
	cores = 1
	# The number of CPU sockets to allocate to the VM.
	sockets = 1
	# Same CPU as the Physical host, possible to add cpu flags (host,kvm64 and ets.)
	cpu = "kvm64"
	# The amount of memory to allocate to the VM in Megabytes.
	memory = 1024
	# The SCSI controller to emulate. Options: lsi, lsi53c810, megasas, pvscsi, virtio-scsi-pci, virtio-scsi-single.
	scsihw = "virtio-scsi-pci"
	# Default boot disk
	bootdisk = "scsi0"
	# 
	disk {
		slot     = 0
		size     = "10G"
		type     = "scsi"
		storage  = "VM"
		iothread = 1
	}
	# if you want two NICs, just copy this whole network section and duplicate it
	network {
		model  = "virtio"
		bridge = "vmbr0"
	}
	# not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
	lifecycle {
		ignore_changes = [
			network,
		]
	}
	# The first IP address to assign to the guest. (ipconfig1 to ipconfig15 - The second IP address to assign to the guest.)
	ipconfig0 = "ip=192.168.0.${221 + count.index + 1}/24,gw=192.168.0.1"
	# Newline delimited list of SSH public keys to add to authorized keys file for the cloud-init user
	sshkeys = <<EOF
	${var.ssh_key}
	EOF
	
	# Post creation actions
	provisioner "remote-exec" {
		inline = [
			"hostname",
			"ip a",
		]
		connection {
			type        = "ssh"
			host        = self.ssh_host
			user        = var.ssh_user
			password    = var.ssh_password
		#	private_key = file("~/.ssh/id_rsa")
		}
	}
}
