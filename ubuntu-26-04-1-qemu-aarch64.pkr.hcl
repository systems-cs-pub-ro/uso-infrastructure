variable "vm_name" {
  type    = string
  default = "uso"
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.ubuntu.com/ubuntu/releases/26.04.1/release/ubuntu-26.04.1-desktop-arm64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:c54d196489d3c867975fb3bbb72ca52ec2e137456e305481f81096304e4d2517"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-26.04.1-desktop-arm64.iso"
}

variable "cpus" {
  type    = number
  default = 4
}

variable "memsize" {
  type    = number
  default = 8192
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
  default = "hvf"
}

variable "firmware" {
  type    = string
  default = "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
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
  default = "aarch64"
}

variable "output_directory" {
  type    = string
  default = "output-qemu-aarch64"
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

source "qemu" "ubuntu-26-04-1-aarch64" {
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  ssh_username         = var.username
  ssh_password         = var.password
  ssh_timeout          = "180m"
  qemu_binary          = "qemu-system-aarch64"
  accelerator          = var.qemu_accelerator
  machine_type         = "virt"
  qemuargs = [
    ["-machine", "virt,accel=hvf"],
    ["-cpu", "host"],
    ["-bios", var.firmware],
    ["-device", "virtio-gpu-pci"],
    ["-device", "qemu-xhci"],
    ["-device", "usb-kbd"],
    ["-device", "usb-tablet"],
    ["-serial", "stdio"],
    ["-boot", "order="]
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
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ console=ttyAMA0,115200 console=tty1 net.ifnames=0 systemd.mask=pd-mapper.service systemd.mask=qrtr-ns.service ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  boot_wait = "30s"
}

build {
  sources = ["sources.qemu.ubuntu-26-04-1-aarch64"]

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
