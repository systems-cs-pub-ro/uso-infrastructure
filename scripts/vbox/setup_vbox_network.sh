#!/bin/bash
set -euo pipefail

# Ensure vboxnet0 host-only interface exists and is configured for autoinstall HTTP server
VBOXMANAGE_BIN="$(command -v VBoxManage || command -v vboxmanage || true)"

if [ -z "$VBOXMANAGE_BIN" ]; then
    echo "Error: VBoxManage/vboxmanage not found in PATH." >&2
    exit 1
fi

if ! "$VBOXMANAGE_BIN" list hostonlyifs | grep -qE '^Name:\s+vboxnet0$'; then
    echo "Creating VirtualBox host-only interface vboxnet0..."
    "$VBOXMANAGE_BIN" hostonlyif create
fi

# Ensure IP address is configured with 192.168.56.1/24
"$VBOXMANAGE_BIN" hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
echo "VirtualBox host-only interface vboxnet0 is ready (192.168.56.1/24)."
