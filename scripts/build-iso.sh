#!/bin/bash
# Assemble the genbox ISO.
#
# Usage: build-iso.sh <rootfs-dir> <initramfs> <output.iso> <repo-dir>
#
# Layout inside the ISO:
#   /boot/genbox/vmlinuz          the kernel
#   /boot/genbox/initramfs.cpio.gz
#   /boot/genbox/rootfs.squashfs  the live root filesystem
#   /boot/grub/grub.cfg           boot menu
set -euo pipefail

root="$(readlink -f "$1")"
initramfs="$(readlink -f "$2")"
out="$3"
repo="$(readlink -f "$4")"

work="$(dirname "$out")/iso.tmp"

log() { printf '\n==> %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "error: build-iso.sh must run as root (mksquashfs reads root-only files)" >&2; exit 1; }

for t in mksquashfs grub2-mkrescue xorriso; do
    command -v "$t" >/dev/null 2>&1 || { echo "error: missing host tool: $t" >&2; exit 1; }
done

# ---------------------------------------------------------------------------
log "locating the live kernel"
kernel="$(ls -1 "$root"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)"
if [ -z "$kernel" ]; then
    echo "error: no kernel found in $root/boot (did the kernel build fail?)" >&2
    exit 1
fi
echo "    $kernel"

# ---------------------------------------------------------------------------
log "building the squashfs root filesystem"
rm -rf "$work"
mkdir -p "$work/boot/genbox" "$work/boot/grub"

mksquashfs "$root" "$work/boot/genbox/rootfs.squashfs" \
    -noappend -comp xz -no-progress \
    -e proc -e sys -e dev -e tmp -e run \
    -e var/tmp/portage -e var/cache/distfiles -e var/cache/binpkgs \
    -e ".built"

# ---------------------------------------------------------------------------
log "copying kernel and initramfs"
cp -L "$kernel" "$work/boot/genbox/vmlinuz"
cp "$initramfs" "$work/boot/genbox/initramfs.cpio.gz"

# ---------------------------------------------------------------------------
log "writing the boot menu"
cat > "$work/boot/grub/grub.cfg" <<'EOF'
set default=0
set timeout=5

menuentry "genbox live installer" {
    linux /boot/genbox/vmlinuz console=tty0 console=ttyS0,115200 quiet
    initrd /boot/genbox/initramfs.cpio.gz
}

menuentry "genbox live installer (verbose)" {
    linux /boot/genbox/vmlinuz console=tty0 console=ttyS0,115200 genbox.debug=1
    initrd /boot/genbox/initramfs.cpio.gz
}

menuentry "genbox live installer (rescue shell)" {
    linux /boot/genbox/vmlinuz console=tty0 console=ttyS0,115200 quiet genbox.rescue=1
    initrd /boot/genbox/initramfs.cpio.gz
}
EOF

# ---------------------------------------------------------------------------
log "assembling the ISO with grub2-mkrescue"
mkdir -p "$(dirname "$out")"
rm -f "$out"
grub2-mkrescue -o "$out" "$work"

log "ISO ready: $out ($(du -h "$out" | cut -f1))"
rm -rf "$work"
