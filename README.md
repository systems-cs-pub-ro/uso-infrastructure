# Build system for USO VMs

This repository contains the build system used for generating USO VMs for labs and ctf.

## Development guide

### Prerequisites

Install `packer` and `ansible` on your machine.

```bash
# Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Get Packer required plugins automatically
packer init ubuntu-25-04-vbox-amd64.pkr.hcl
# Or install them manually
packer plugins install github.com/hashicorp/virtualbox
packer plugins install github.com/hashicorp/ansible

# Ansible
sudo apt install ansible
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
