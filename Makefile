root_dir     := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
output_dir   ?= $(abspath $(root_dir)/output)
headless     ?= true

all: ubuntu-25-04

ubuntu-25-04: ubuntu-25-04-vbox.pkr.hcl
	packer build -var headless=$(headless) $<

clean:
	rm -rf $(output_dir)
