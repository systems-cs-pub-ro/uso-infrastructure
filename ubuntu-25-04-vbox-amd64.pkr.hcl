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
  default = "https://releases.ubuntu.com/releases/25.04/ubuntu-25.04-desktop-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:b87366b62eddfbecb60e681ba83299c61884a0d97569abe797695c8861f5dea4"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-25.04-desktop-amd64.iso"
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
  default = 40000
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

source "virtualbox-iso" "ubuntu-25-04" {
  guest_os_type = var.guest_os_type
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  ssh_username  = var.username
  ssh_password  = var.password
  ssh_timeout   = "180m"
   http_content = {
     "/user-data" = templatefile("scripts/autoinst/ubuntu-25-04-autoinstall.yml", {
       user = {
         username = var.username
         password = bcrypt(var.password)
       }
       hostname = var.vm_name
     }),
     "/meta-data" = ""
   }
  shutdown_command     = "rm -rf ~/.ansible && echo '${var.password}' | sudo -S poweroff"
  disk_size            = var.disk_size
  vm_name              = "${var.img_name}"
  format               = var.disk_format
  cpus                 = var.cpus
  memory               = var.memsize
  headless             = var.headless
  output_directory     = var.output_directory

  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--boot1", "dvd"],
    ["modifyvm", "{{ .Name }}", "--boot2", "disk"],
    ["modifyvm", "{{ .Name }}", "--usb", "off"],
    ["modifyvm", "{{ .Name }}", "--vram", "128"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--nic2", "hostonly"],
    ["modifyvm", "{{ .Name }}", "--hostonlyadapter2", "VirtualBox Host-Only Ethernet Adapter"],
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memsize}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"]
  ]

  boot_command         = [
    "e<wait>",
    "<down><down><down>",
    "<end><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>",
    "nomodeset autoinstall ds=nocloud-net\\;s=http://192.168.56.1:{{ .HTTPPort }}/ net.ifnames=0<wait>",
    "<f10><wait>"
  ]

  boot_wait = "5s"
}

build {
  sources = ["sources.virtualbox-iso.ubuntu-25-04"]

  provisioner "ansible" {
    playbook_file    = "scripts/ansible/ubuntu-25-04.yml"
    user             = var.username
    use_proxy        = false
    extra_arguments  = [
      "--extra-vars", "ansible_password='${var.password}' ansible_become_pass='${var.password}'",
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
