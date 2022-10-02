# Test Packer

This repository contains the scripts to generate VMs for USO.

The VMs:
* are based Ubuntu 22.04 Live Server;
* `ubuntu-desktop-minimal` is installed and enabled;
* are saved as  `.ova` (to import them either in VirtualBox or VMware);

For Apple/M1 users the `ova` is exported into `.qcow2` and it
can be launched with UTM or Qemu.   

## Prerequisites

Install `packer`, `ansible` and `sshpass`:

```bash
# Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Ansible
sudo apt install ansible

# sshpass
sudo apt install sshpass
```

## Build VM

We provided a Makefile to easy generate the VMs:

To run custom build commands for debugging, run:

```bash
packer build -var headless=false <packer_hcl_script>
```
