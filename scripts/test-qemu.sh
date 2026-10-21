#!/bin/bash
# Boot the genbox ISO in QEMU.
# Usage: test-qemu.sh <iso> [disk-image]
set -euo pipefail

iso="$1"
disk="${2:-}"

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
    echo "error: qemu-system-x86_64 is not installed" >&2
    exit 1
}

args=(
    -m 4096
    -smp 4
    -cdrom "$iso"
    -boot d
    -nic user,model=virtio-net-pci
    -serial stdio
    -display none
    -no-reboot
)

# Use KVM when the current user may access it.
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    args+=(-enable-kvm -cpu host)
fi

if [ -n "$disk" ]; then
    args+=(-drive "file=$disk,format=raw,if=virtio")
fi

echo "==> booting $iso in QEMU (Ctrl-A X to quit)"
exec qemu-system-x86_64 "${args[@]}"
