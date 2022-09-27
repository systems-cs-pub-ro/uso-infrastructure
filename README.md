# Test Packer

This repository is used to play around with examples from Packer.

To build Ubuntu 20.04.3 image into `qcow2` format, run the following:

```bash
packer build -var headless=false ubuntu-20-04.pkr.hcl
```

To build Ubuntu 20.04.3 image into `ova` format, run the following:

```bash
packer build -var headless=false ubuntu-20-04-vbox.pkr.hcl
```

