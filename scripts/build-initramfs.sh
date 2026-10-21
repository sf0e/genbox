#!/bin/bash
# Build the genbox live initramfs.
#
# Usage: build-initramfs.sh <rootfs-dir> <output.cpio.gz>
#
# The initramfs is a BusyBox-based image that:
#   1. mounts proc/sys/dev
#   2. loads the storage/loop/squashfs/overlay modules
#   3. finds the boot medium (ISO or USB) by looking for
#      /boot/genbox/rootfs.squashfs
#   4. mounts the squashfs read-only and puts a tmpfs-backed overlay on top
#   5. switch_root into it
set -euo pipefail

root="$(readlink -f "$1")"
out="$(readlink -f "$2")"
work="$(dirname "$out")/initramfs.tmp"

if [ "$(id -u)" -ne 0 ]; then
    echo "error: build-initramfs.sh must run as root (use sudo)" >&2
    exit 1
fi

log() { printf '\n==> %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Locate the kernel we just built/downloaded.
kver="$(ls -1 "$root/lib/modules" 2>/dev/null | sort -V | tail -1)"
if [ -z "$kver" ]; then
    echo "error: no kernel modules found under $root/lib/modules" >&2
    exit 1
fi
log "using kernel $kver"

if [ ! -d "$root/lib/modules/$kver" ]; then
    echo "error: $root/lib/modules/$kver missing" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
log "staging initramfs in $work"
rm -rf "$work"
mkdir -p "$work"/{bin,sbin,etc,proc,sys,dev,run,tmp,lib,lib64,mnt/cdrom,mnt/root-ro,mnt/root-rw,mnt/root}

# ---------------------------------------------------------------------------
log "copying busybox and its libraries"
cp "$root/bin/busybox" "$work/bin/busybox"
chmod 755 "$work/bin/busybox"

# Copy the dynamic loader and libraries that busybox needs. Resolve them
# inside the rootfs so we copy the rootfs's libc, not the build host's.
copy_libs() {
    chroot "$root" ldd /bin/busybox 2>/dev/null \
        | awk '/=>/ { print $3 } /ld-linux/ { print $1 }' \
        | while read -r lib; do
            [ -n "$lib" ] || continue
            [ -e "$root$lib" ] || continue
            local dest="$work$lib"
            mkdir -p "$(dirname "$dest")"
            cp -L "$root$lib" "$dest"
        done
}
copy_libs

# Create applet symlinks.
chroot "$root" /bin/busybox --list | while read -r applet; do
    [ -n "$applet" ] || continue
    ln -sf busybox "$work/bin/$applet"
done

# ---------------------------------------------------------------------------
log "copying kernel modules"
mkdir -p "$work/lib/modules"
cp -a "$root/lib/modules/$kver" "$work/lib/modules/"

# ---------------------------------------------------------------------------
log "writing /init"
cat > "$work/init" <<'INIT'
#!/bin/busybox sh
# genbox live initramfs init
case "$(cat /proc/cmdline 2>/dev/null)" in
    *genbox.debug=1*) set -x ;;
esac

export PATH=/bin:/sbin
export HOME=/root

rescue_shell() {
    echo
    echo "genbox: dropping to a rescue shell"
    echo "The live medium could not be mounted."
    exec /bin/sh
}

mountpoint -q /proc || mount -t proc proc /proc
mountpoint -q /sys  || mount -t sysfs sysfs /sys
if ! mountpoint -q /dev; then
    mount -t devtmpfs devtmpfs /dev 2>/dev/null || {
        mount -t tmpfs dev /dev
        mdev -s
    }
fi

mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts 2>/dev/null || true
mount -t tmpfs tmpfs /dev/shm 2>/dev/null || true

if [ -w /proc/sys/kernel/hotplug ]; then
    echo /bin/mdev > /proc/sys/kernel/hotplug 2>/dev/null || true
fi
mdev -s 2>/dev/null || true

case "$(cat /proc/cmdline)" in
    *genbox.rescue=1*) exec /bin/sh ;;
esac

# Make sure the modules we need for the live medium exist.
for m in loop squashfs isofs overlay sr_mod sd_mod ahci virtio_blk virtio_pci \
         nvme nvme_core usb_storage xhci_hcd ehci_pci ohci_pci uhci_hcd; do
    modprobe "$m" 2>/dev/null || true
done

# Find a device that contains the genbox root filesystem. Retry for a while:
# USB and optical devices can take several seconds to appear.
found=""
attempt=0
while [ -z "$found" ] && [ "$attempt" -lt 20 ]; do
    mdev -s 2>/dev/null || true
    for d in /dev/sr* /dev/sd* /dev/vd* /dev/nvme*n* /dev/mmcblk*; do
        [ -b "$d" ] || continue
        mount -t iso9660 -o ro "$d" /mnt/cdrom 2>/dev/null || continue
        if [ -f /mnt/cdrom/boot/genbox/rootfs.squashfs ]; then
            found="$d"
            break
        fi
        umount /mnt/cdrom 2>/dev/null || true
    done
    [ -n "$found" ] && break
    attempt=$((attempt + 1))
    sleep 1
done

if [ -z "$found" ]; then
    # Last resort: try the root= parameter.
    for param in $(cat /proc/cmdline); do
        case "$param" in
            genbox.root=*)
                d="${param#genbox.root=}"
                mount -t iso9660 -o ro "$d" /mnt/cdrom 2>/dev/null && found="$d"
                ;;
        esac
    done
fi

[ -n "$found" ] || rescue_shell
echo "genbox: live medium found on $found"

# Mount the root filesystem image.
if ! mount -t squashfs -o ro,loop /mnt/cdrom/boot/genbox/rootfs.squashfs /mnt/root-ro 2>/dev/null; then
    modprobe squashfs 2>/dev/null || true
    mount -t squashfs -o ro,loop /mnt/cdrom/boot/genbox/rootfs.squashfs /mnt/root-ro 2>/dev/null || rescue_shell
fi

# Put a writable tmpfs overlay on top, so the live system can write.
if mount -t tmpfs -o mode=0755 tmpfs /mnt/root-rw 2>/dev/null; then
    mkdir -p /mnt/root-rw/upper /mnt/root-rw/work
    if mount -t overlay -o "lowerdir=/mnt/root-ro,upperdir=/mnt/root-rw/upper,workdir=/mnt/root-rw/work" overlay /mnt/root 2>/dev/null; then
        echo "genbox: using a writable overlay"
    else
        echo "genbox: overlay unavailable, using read-only root with tmpfs mounts"
        mount --move /mnt/root-ro /mnt/root
        mkdir -p /mnt/root/run /mnt/root/tmp /mnt/root/var/tmp /mnt/root/var/log
        mount -t tmpfs tmpfs /mnt/root/run
        mount -t tmpfs tmpfs /mnt/root/tmp
        mount -t tmpfs tmpfs /mnt/root/var/tmp
        mount -t tmpfs tmpfs /mnt/root/var/log
    fi
else
    mount --move /mnt/root-ro /mnt/root
fi

mkdir -p /mnt/root/proc /mnt/root/sys /mnt/root/dev /mnt/root/run
mount --move /proc /mnt/root/proc
mount --move /sys  /mnt/root/sys
mount --move /dev  /mnt/root/dev

echo "genbox: switching root"
exec switch_root /mnt/root /sbin/init
INIT
chmod 755 "$work/init"

# ---------------------------------------------------------------------------
log "packing $out"
mkdir -p "$(dirname "$out")"
( cd "$work" && find . -print0 | cpio --null -o --format=newc 2>/dev/null ) | gzip -6 > "$out"

log "initramfs ready: $out ($(du -h "$out" | cut -f1))"
rm -rf "$work"
