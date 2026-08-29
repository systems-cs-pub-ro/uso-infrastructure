variable "vm_name" {
  type    = string
  default = "uso"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/26.04.1/ubuntu-26.04.1-desktop-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:601e30fbf5d97759367c632e2c33630665039b7e2158fd068403da3ccf1bda1f"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-26.04.1-desktop-amd64.iso"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memsize" {
  type    = number
  default = 4096
}

variable "disk_size" {
  type    = number
  default = 40000
}

variable "ctf_disk_size" {
  type    = string
  default = "100M"
}

variable "qemu_accelerator" {
  type    = string
  default = "kvm"
}

variable "firmware" {
  type    = string
  default = "/usr/share/OVMF/x64/OVMF.4m.fd"
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
  default = false
}

variable "img_name" {
  type    = string
  default = "USO"
}

variable "arch" {
  type    = string
  default = "amd64"
}

variable "output_directory" {
  type    = string
  default = "output-qemu-amd64"
}

variable "checksum_directory" {
  type    = string
  default = "checksums"
}

packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "qemu" "ubuntu-26-04-1-amd64" {
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  ssh_username         = var.username
  ssh_password         = var.password
  ssh_timeout          = "180m"
  qemu_binary          = "qemu-system-x86_64"
  accelerator          = var.qemu_accelerator
  machine_type         = "q35"
  qemuargs = [
    ["-bios", var.firmware],
    ["-device", "qemu-xhci"],
    ["-device", "usb-tablet"],
    ["-serial", "stdio"]
  ]
  cpus                 = var.cpus
  memory               = var.memsize
  disk_size            = var.disk_size
  disk_additional_size = [ var.ctf_disk_size ]
  disk_interface       = "virtio"
  net_device           = "virtio-net"
  format               = var.disk_format
  vm_name              = "${var.img_name}-${var.arch}.${var.disk_format}"
  headless             = var.headless
  output_directory     = var.output_directory

  http_content = {
    "/user-data" = templatefile("scripts/autoinst/ubuntu-26-04-1-autoinstall.yml", {
      user = {
        username = var.username
        password = bcrypt(var.password)
      }
      hostname    = var.vm_name
      arch        = var.arch
      disk_main   = "/dev/vda"
      disk_second = "/dev/vdb"
    }),
    "/meta-data" = ""
  }

  shutdown_command     = "rm -rf ~/.ansible && echo '${var.password}' | sudo -S poweroff"

  boot_command         = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ console=ttyS0,115200 console=tty1 net.ifnames=0 ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  boot_wait = "5s"
}

build {
  sources = ["sources.qemu.ubuntu-26-04-1-amd64"]

  provisioner "ansible" {
    playbook_file    = "scripts/ansible/ubuntu-26-04-1.yml"
    user             = var.username
    use_proxy        = false
    extra_arguments  = [
      "--extra-vars", "ansible_password='${var.password}' ansible_become_password='${var.password}' ansible_become_pass='${var.password}'",
    ]
  }

  post-processor "shell-local" {
    inline = ["rm -f ${var.checksum_directory}/${var.img_name}-${var.arch}.*"]
  }

  post-processor "checksum" {
    checksum_types = ["sha256", "sha512"]
    output = "${var.checksum_directory}/${var.img_name}-${var.arch}.{{.ChecksumType}}"
  }
}
