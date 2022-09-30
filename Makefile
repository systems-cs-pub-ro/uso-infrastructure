root_dir     := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
scripts_dir  ?= $(abspath $(root_dir)/scripts)
output_dir   ?= $(abspath $(root_dir)/output)
checksum_dir ?= $(abspath $(root_dir)/checksums)
autoinst_dir ?= $(abspath $(scripts_dir)/autoinst)
playbook_dir ?= $(abspath $(scripts_dir)/ansible)
headless     ?= false

all: ubuntu-22-04

ubuntu-22-04: ubuntu-22-04-vbox.pkr.hcl
	packer build -var headless=$(headless) $<

clean:
	rm -rf $(output_dir)

clean-all:
	rm -rf $(output_dir)
	rm -rf ~/.cache/packer/*
