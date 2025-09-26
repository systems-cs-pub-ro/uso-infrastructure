root_dir     := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
output_dir   ?= $(abspath $(root_dir)/output)
headless     ?= true

all: amd64 arm64

amd64: ubuntu-25-04-vbox-amd64.pkr.hcl
	packer build -var headless=$(headless) $<

arm64: ubuntu-25-04-vbox-arm64.pkr.hcl
	packer build -var headless=$(headless) $<

clean:
	rm -rf $(output_dir)
