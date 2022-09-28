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
  #default = "https://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04/release/ubuntu-20.04.1-legacy-server-amd64.iso"
  default = "https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso"
  # default = "https://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  #default = "sha256:f11bda2f2caed8f420802b59f382c25160b114ccc665dbac9c5046e7fceaced2"
  # default = "sha256:f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
  default = "5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-20.04.3-live-server-amd64.iso"
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

variable "preseed" {
  type    = string
  default = "preseed.cfg"
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}

variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
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
  shutdown_command     = "echo '${var.password}' | sudo -S poweroff"
  disk_size            = var.disk_size
  vm_name              = "${var.img_name}"
  format               = "ova"
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

#  boot_command = [
#      "c<wait>",
#      "<esc><esc><enter><wait>",
#      "/install/vmlinuz noapic",
#      " initrd=/install/initrd.gz",
#      " auto=true",
#      " priority=critical",
#      " debian-installer=en_US auto locale=en_US kbd-chooser/method=us ",
#      " hostname=${var.vm_name} ", 
#      " grub-installer/bootdev=/dev/sda<wait> ", 
#      " fb=false debconf/frontend=noninteractive ", 
#      " keyboard-configuration/modelcode=SKIP keyboard-configuration/layout=USA ", 
#      " keyboard-configuration/variant=USA console-setup/ask_detect=false ",
#      " passwd/user-fullname=${var.username} ", 
#      " passwd/user-password=${var.password} ", 
#      " passwd/user-password-again=${var.password} ", 
#      " passwd/username=${var.username} ",
#      " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.preseed} ",
#      " -- <enter>"
#  ]

      boot_command = [
        "<enter><enter><f6><esc><wait> ",
        "autoinstall ds=nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
        "<wait><enter><wait>"
      ]

  boot_wait = "5s"
}

build {
  sources = ["sources.virtualbox-iso.ubuntu-20-04"]
  
  provisioner "file" {
    source      = "/home/stefan/.ssh/id_rsa.pub"
    destination = "/home/student/authorized_keys"
  }

  provisioner "ansible" {
    playbook_file    = "scripts/ansible/ubuntu-22-04.yml"
    user             = var.username
    use_proxy        = false
    extra_arguments  = [
      "--extra-vars", "ansible_password='${var.password}' ansible_become_pass='${var.password}'",
    ]
  }
  
  #provisioner "shell" {
  #  environment_vars  = [
  #    "DEBIAN_FRONTEND=noninteractive", 
  #    "UPDATE=true", 
  #    "SSH_USERNAME=${var.username}", 
  #    "SSH_PASSWORD=${var.password}", 
  #    "http_proxy=${var.http_proxy}", 
  #    "https_proxy=${var.https_proxy}", 
  #    "no_proxy=${var.no_proxy}"
  #  ]
  #  execute_command   = "echo '${var.password}'|{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
  #  expect_disconnect = true
  #  scripts           = [
  #    "scripts/vbox/update.sh", 
  #    "scripts/vbox/cleanup.sh",
  #    "scripts/vbox/ssh.sh"
  #  ]
  #}
}
