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
  default = "https://releases.ubuntu.com/20.04.1/ubuntu-20.04.1-live-server-amd64.iso"
#  default = "https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "443511f6bf12402c12503733059269a2e10dec602916c0a75263e5d990f6bb93"
#  default = "5035be37a7e9abbdc09f0d257f3e33416c1a0fb322ba860d42d74aa75c3468d4"
# default = "10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
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

source "virtualbox-iso" "ubuntu-22-04" {
  guest_os_type = var.guest_os_type
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  ssh_username  = var.username
  ssh_password  = var.password
  ssh_timeout   = "60m"
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
  boot_wait = "5s"
  boot_command = [
        #"<esc><wait><esc><wait><esc><wait><enter><wait>",
	"<esc><esc><wait><f6><wait><esc><wait><tab>",
        #"initrd=/casper/initrd quiet --- ",
        "net.ifnames=0 ",
        "autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/<wait><enter>"
      ]
  #boot_key_interval = "20ms"
}

build {
  sources = ["sources.virtualbox-iso.ubuntu-22-04"]

  provisioner "ansible" {
    playbook_file = "scripts/ansible/ubuntu-22-04.yml"
    user          = var.username
    use_proxy     = false
    extra_arguments = [
      "--extra-vars", "ansible_password='${var.password}' ansible_become_pass='${var.password}'",
    ]
  }
}
