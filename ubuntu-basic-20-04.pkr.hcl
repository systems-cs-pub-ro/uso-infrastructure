variable "vm_name" {
  type    = string
  default = "uso"
}

variable "guest_os_type" {
  type    = string
  default = "Ubuntu_64"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-20.04.5-live-server-amd64.iso"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memsize" {
  type    = number
  default = 2048
}

variable "disk_size" {
  type    = number
  default = 20000
}

variable "qemu_accelerator" {
  type    = string
  default = "kvm"
}

variable "disk_compression" {
  type    = bool
  default = false
}

variable "disk_format" {
  type    = string
  default = "qcow2"
}

variable "username" {
  type    = string
  default = "student"
}

variable "password" {
  type    = string
  default = "student"
}

variable "headless" {
  type    = bool
  default = true
}

variable "img_name" {
  type    = string
  default = "USO 2022-2023"
}

variable "guest_additions_mode" {
  type    = string
  default = "disable"
}

variable "output_directory" {
  type    = string
  default = "output"
}

source "qemu" "ubuntu-20-04-3" {
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  cpus             = var.cpus
  memory           = var.memsize
  disk_size        = var.disk_size
  disk_interface   = "virtio"
  disk_compression = var.disk_compression
  format           = var.disk_format
  http_content = {
    "/user-data" = templatefile("scripts/autoinst/ubuntu-22-04-autoinstall.yml", {
      user = {
        username = var.username
        password = bcrypt(var.password)
      }
      hostname = var.vm_name
    }),
    "/meta-data" = ""
  }
  accelerator      = var.qemu_accelerator
  ssh_username     = var.username
  ssh_password     = var.password
  ssh_timeout      = "50m"
  shutdown_command = "rm -rf ~/.ansible && echo '${var.password}' | sudo -S poweroff"
  vm_name          = "${var.img_name}"
  net_device       = "virtio-net"
  headless         = var.headless
  output_directory = "${var.output_directory}/${var.vm_name}"
  boot_wait        = "1s"
  boot_command = [
    "<bs><esc><f6><esc><tab> ",
    "net.ifnames=0 ",
    "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/<enter>"
  ]
  boot_key_interval = "20ms"
}

build {
  sources = ["sources.qemu.ubuntu-20-04-3"]

  provisioner "ansible" {
    playbook_file = "scripts/ansible/ubuntu-22-04.yml"
    user          = var.username
    use_proxy     = false
    extra_arguments = [
      "--extra-vars", "ansible_password='${var.password}' ansible_become_pass='${var.password}'",
    ]
  }

  post-processor "shell-local" {
    inline = ["qemu-img snapshot -c new '${var.output_directory}/${var.vm_name}/${var.img_name}'"]
  }
}
