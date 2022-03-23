variable "proxmox_host" {
	default = "Hostname Proxmox"
}

variable "template_name" {
	default = "Ubuntu-Custom-Template"
}

variable "ssh_key" {
	default = "SSH public key"
}

variable "ssh_user" {
	description = "initial ssh root user"
	type        = string
}

variable "ssh_password" {
	description = "initial ssh root password"
	type        = string
}
