root_dir     := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
output_dir   ?= $(abspath $(root_dir)/output)
headless     ?= true

.PHONY: all amd64 aarch64 arm64 qemu-amd64 qemu-aarch64 qcow2 qcow2-amd64 qcow2-aarch64 vbox-amd64 clean

all: qcow2

# QEMU / QCOW2 Targets
qcow2: qemu-amd64 qemu-aarch64

qemu-amd64: ubuntu-26-04-1-qemu-amd64.pkr.hcl
	packer build -var headless=$(headless) $<

qemu-aarch64: ubuntu-26-04-1-qemu-aarch64.pkr.hcl
	packer build -var headless=$(headless) $<

qcow2-amd64: qemu-amd64
qcow2-aarch64: qemu-aarch64
aarch64: qemu-aarch64
arm64: qemu-aarch64

# VirtualBox Targets
amd64: vbox-amd64

vbox-amd64: ubuntu-26-04-1-vbox-amd64.pkr.hcl
	./scripts/vbox/setup_vbox_network.sh
	packer build -var headless=$(headless) $<

clean:
	rm -rf $(root_dir)/output* $(output_dir)
