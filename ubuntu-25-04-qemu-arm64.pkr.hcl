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
  default = "https://cdimage.ubuntu.com/releases/plucky/release/ubuntu-25.04-desktop-arm64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:5a8be80b24cbc3f7a9c0d73d8c5d496602a30b7e0f91945ab72f75188a9780e7"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-25.04-desktop-arm64.iso"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memsize" {
  type    = number
  default = 3096
}

variable "disk_size" {
  type    = number
  default = 30000
}

variable "qemu_accelerator" {
  type    = string
  default = "tcg"
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

variable "output_directory" {
  type    = string
  default = "output-aarch64"
}

variable "checksum_directory" {
  type    = string
  default = "checksums"
}

source "qemu" "ubuntu-25-04-aarch64" {
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  ssh_username  = var.username
  ssh_password  = var.password
  qemu_binary   = "qemu-system-aarch64"
  qemuargs = [
    ["-machine", "virt"],
    ["-cpu", "cortex-a57"],
    ["-bios", "/usr/share/AAVMF/AAVMF_CODE.fd"],
    ["-boot", "order="]
  ]

  accelerator   = var.qemu_accelerator
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
  disk_interface       = "virtio"
  net_device           = "virtio-net"
  vm_name              = "${var.img_name}"
  format               = var.disk_format
  cpus                 = var.cpus
  memory               = var.memsize
  headless             = var.headless
  output_directory     = var.output_directory

  boot_command         = [
    "<bs><esc><f6><esc><tab> ",
    "nomodeset autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ net.ifnames=0<wait>",
    "<f10><wait>"
  ]

  boot_wait = "5s"
  boot_key_interval = "50ms"
}

build {
  sources = ["sources.qemu.ubuntu-25-04-aarch64"]

  post-processor "shell-local" {
    inline = ["rm -f ${var.checksum_directory}/${var.img_name}.*"]
  }

  post-processor "checksum" {
    checksum_types = ["sha256", "sha512"]
    output = "${var.checksum_directory}/${var.img_name}.{{.ChecksumType}}"
  }
}
