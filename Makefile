root_dir     := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
output_dir   ?= $(abspath $(root_dir)/output)
headless     ?= true

.PHONY: all amd64 vbox-amd64 clean

all: amd64

amd64: vbox-amd64

vbox-amd64: ubuntu-26-04-1-vbox-amd64.pkr.hcl
	packer build -var headless=$(headless) $<

clean:
	rm -rf $(root_dir)/output* $(output_dir)
