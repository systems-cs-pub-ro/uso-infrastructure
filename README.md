# Build system for USO VMs

This repository contains the build system used for generating USO VMs for labs and ctf.

## Development guide

### Prerequisites

Install the following dependencies on your machine:
- `packer`: https://developer.hashicorp.com/packer/install#linux
- `ansible`: https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu

Packer requires the following plugins to be installed:

```bash
# Get Packer required plugins automatically
packer init ubuntu-25-04-vbox-amd64.pkr.hcl
# Or install them manually
packer plugins install github.com/hashicorp/virtualbox
packer plugins install github.com/hashicorp/ansible
```

### Technical Details

The lifecycle of building the VM is:
- download the corresponding Ubuntu image and configure the VM resources using `packer`. All the configs are available in `ubuntu-*.pkr.hcl`.
- allow installation leveraging `cloud-init` and the `autoinstall` feature from Ubuntu. The configuration available in the GUI installation wizard are available in `scripts/autoinst/ubuntu-*-autoinstall,yml`.
- all the other config required for the USO lab environment are set using ansible. The scrips are available in `scripts/ansible/*.yml`

### How to Build the VM

A Makefile is availale for building the VM:
```bash
make
```

For debugging purposes, start the build as following:

```bash
PACKER_LOG=1 packer build -var headless=false ubuntu-*-vbox.pkr.hcl
```

## References
The cookbook guid for configuring VMs are available at [the following link](https://github.com/cs-pub-ro/lab-infrastructure/blob/master/install/uso-vm-actions.txt).

The scripts were inspired from [this repository](https://gitlab.cs.pub.ro/SCGC/packer).
