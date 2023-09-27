# USO Virtual Machine

This repository containes instructions and scripts on how to build the virtual machine for USO.

Currently the VM is based on Ubuntu Desktop 22.04.

The VM is built using `vbox` and `ansible`.

## Notes

A completely automates setup can be found under the branch `packer-setup`.

The limitation of that workflow is it cannot support Desktop versions, just Live Servers.

## References

The scripts and configs for the vm are based on the following [instructions](https://github.com/cs-pub-ro/lab-infrastructure/blob/master/install/uso-vm-actions.txt).
