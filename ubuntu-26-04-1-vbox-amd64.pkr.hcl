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
  type    = number
  default = 100
}

variable "disk_format" {
  type    = string
  default = "ova"
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
  default = "output-amd64"
}

variable "checksum_directory" {
  type    = string
  default = "checksums"
}

packer {
  required_plugins {
    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

source "virtualbox-iso" "ubuntu-26-04-1" {
  guest_os_type = var.guest_os_type
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  ssh_username  = var.username
  ssh_password  = var.password
  ssh_timeout   = "180m"
  http_content = {
    "/user-data" = templatefile("scripts/autoinst/ubuntu-26-04-1-autoinstall.yml", {
      user = {
        username = var.username
        password = bcrypt(var.password)
      }
      hostname    = var.vm_name
      arch        = var.arch
      disk_main   = "/dev/sda"
      disk_second = "/dev/sdb"
    }),
    "/meta-data" = ""
  }
  shutdown_command     = "rm -rf ~/.ansible && echo '${var.password}' | sudo -S poweroff"
  disk_size            = var.disk_size
  disk_additional_size = [ var.ctf_disk_size ]
  vm_name              = "${var.img_name}"
  format               = var.disk_format
  cpus                 = var.cpus
  memory               = var.memsize
  headless             = var.headless
  output_directory     = var.output_directory

  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--firmware", "efi"],
    ["modifyvm", "{{ .Name }}", "--boot1", "dvd"],
    ["modifyvm", "{{ .Name }}", "--boot2", "disk"],
    ["modifyvm", "{{ .Name }}", "--usb", "off"],
    ["modifyvm", "{{ .Name }}", "--vram", "128"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--nic2", "hostonly"],
    ["modifyvm", "{{ .Name }}", "--hostonlyadapter2", "vboxnet0"],
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memsize}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"]
  ]

  boot_command         = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://192.168.56.1:{{ .HTTPPort }}/ net.ifnames=0 ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  boot_wait = "5s"
}

build {
  sources = ["sources.virtualbox-iso.ubuntu-26-04-1"]

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
