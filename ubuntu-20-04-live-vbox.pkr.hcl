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
  default = "https://releases.ubuntu.com/focal/ubuntu-20.04.5-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4"
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

variable "format" {
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

packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-iso" "ubuntu-20-04" {
  guest_os_type = var.guest_os_type
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  ssh_username  = var.username
  ssh_password  = var.password
  ssh_timeout   = "30m"
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
  shutdown_command     = "rm -rf ~/.ansible && echo '${var.password}' | sudo -S poweroff"
  disk_size            = var.disk_size
  vm_name              = "${var.img_name}"
  format               = var.format
  cpus                 = var.cpus
  memory               = var.memsize
  headless             = var.headless
  guest_additions_mode = var.guest_additions_mode
  virtualbox_version_file = ".vbox_version"
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--usb", "off"],
    ["modifyvm", "{{ .Name }}", "--vram", "12"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--nictype1", "virtio"],
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memsize}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"]
  ]
  output_directory = var.output_directory
  
  # boot_command = [
  #   "<enter><enter><f6><esc><wait> ",
  #   "autoinstall ds=nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
  #   "<wait><enter><wait>"
  # ]

  boot_wait = "5s"
}

build {
  sources = ["sources.virtualbox-iso.ubuntu-20-04"]
  
  provisioner "file" {
    source      = "/home/andreia/.ssh/id_ed25519.pub"
    destination = "/home/student/authorized_keys"
  }

  provisioner "ansible" {
    playbook_file    = "scripts/ansible/ubuntu-20-04.yml"
    user             = var.username
    use_proxy        = false
    extra_arguments  = [
      "--extra-vars", "ansible_password='${var.password}' ansible_become_pass='${var.password}'",
    ]
  }

}