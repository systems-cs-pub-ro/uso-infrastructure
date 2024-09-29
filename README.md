# USO Virtual Machine

This repository contains instructions and scripts on how to build the virtual machine for the USO course.

The VM is built using `vbox` and `ansible`.

## Steps
1. Download the ISO for the LTS version of Ubuntu Desktop.
2. Install `vbox` on your host.
3. Create a new VM in `vbox` using the downloaded ISO. Note: you might need to increase CPU/RAM to speed up the installation.
4. Run the `vbox` script to configure the VM.
5. Install `ansible-core` on the VM.
6. Install `openssh-server` on the VM.
7. Install VirtualBox Guest Additions on the VM.
8. `scp` the `ansible` playbook to the VM.
9. Run the `ansible` playbook to install the necessary software.
10. Clean up the VM:
    * Remove the `ansible` playbook.
    * Uninstall `ansible-core`.
11. Export the VM as an `ova` file.

Useful commands:
```bash
# Install ansible-core
sudo apt update
sudo apt install ansible -y

# Install openssh-server
sudo apt install openssh-server -y

# Install VirtualBox Guest Additions
sudo apt install build-essential dkms linux-headers-$(uname -r) -y
sudo mount /dev/cdrom /media/cdrom
sudo /media/cdrom/VBoxLinuxAdditions.run

# Ansible commands
ansible-playbook ubuntu.yml --syntax-check
ansible-playbook ubuntu.yml
```

## Notes

### 2024 - 2025

* The VM is based on Ubuntu Desktop 24.04 - Download the ISO from [here](https://releases.ubuntu.com/24.04/).

### 2023 - 2024

* The VM is based on Ubuntu Desktop 22.04 - Download the ISO from [here](https://releases.ubuntu.com/22.04/).

## References

The scripts and configs for the vm are based on the following [instructions](https://github.com/cs-pub-ro/lab-infrastructure/blob/master/install/uso-vm-actions.txt).
