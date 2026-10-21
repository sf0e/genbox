#!/bin/bash
# Build the genbox root filesystem.
#
# Usage: build-rootfs.sh <stage3-tarball> <root-dir> <repo-dir> [jobs] [live-kernel]
#
# Steps:
#   1. extract the stage3 into <root-dir>
#   2. copy the genbox overlay to /var/db/repos/genbox
#   3. wire repos.conf and the profile
#   4. unmerge openrc / sysvinit / udev (before genbox-init, to avoid collisions)
#   5. emerge genbox-init, busybox, the live kernel, installer tools
#   6. install the installer, make.conf and documentation
set -euo pipefail

stage3="$(readlink -f "$1")"
root="$(readlink -f "$2")"
repo="$(readlink -f "$3")"
jobs="${4:-$(nproc)}"
live_kernel="${5:-source}"

log() { printf '\n==> %s\n' "$*"; }

need() {
    command -v "$1" >/dev/null 2>&1 || { echo "error: missing host tool: $1" >&2; exit 1; }
}
need sudo
need tar
need cp

# ---------------------------------------------------------------------------
mounts_under() {
    local d="$1"
    awk -v d="$d" '$2 == d || index($2, d "/") == 1 { print $2 }' /proc/mounts
}

unmount_under() {
    local d="$1"
    mounts_under "$d" | tac | while read -r m; do
        [ -n "$m" ] && sudo umount -l "$m" 2>/dev/null || true
    done || true
}

safe_rm_rf() {
    local d="$1"
    if [ -n "$(mounts_under "$d")" ]; then
        echo "error: refusing to rm -rf $d: filesystems are mounted beneath it" >&2
        mounts_under "$d" >&2
        exit 1
    fi
    sudo rm -rf -- "$d"
}

if [ -x "$root/bin/bash" ] && [ "${GENBOX_REUSE_ROOTFS:-0}" = "1" ]; then
    log "reusing existing rootfs at $root"
else
    log "extracting stage3 into $root"
    unmount_under "$root"
    safe_rm_rf "$root"
    sudo mkdir -p "$root"
    sudo tar -xpf "$stage3" -C "$root"
fi

# ---------------------------------------------------------------------------
log "installing the genbox overlay"
sudo rm -rf "$root/var/db/repos/genbox"
sudo mkdir -p "$root/var/db/repos"
sudo cp -a "$repo/overlay" "$root/var/db/repos/genbox"

# ---------------------------------------------------------------------------
log "configuring portage (repos.conf + profile)"
sudo mkdir -p "$root/etc/portage/repos.conf"
sudo tee "$root/etc/portage/repos.conf/gentoo.conf" >/dev/null <<'EOF'
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/db/repos/gentoo

[genbox]
location = /var/db/repos/genbox
EOF

sudo ln -sfn ../../var/db/repos/genbox/profiles/genbox/linux/amd64 \
    "$root/etc/portage/make.profile"

# ---------------------------------------------------------------------------
log "preparing the chroot"
sudo cp -L /etc/resolv.conf "$root/etc/resolv.conf" || true
for m in dev dev/pts dev/shm proc sys; do
    sudo mkdir -p "$root/$m"
done

chroot_run() {
    sudo chroot "$root" \
        /usr/bin/env -i \
        HOME=/root \
        TERM="${TERM:-linux}" \
        PATH=/usr/sbin:/usr/bin:/sbin:/bin \
        MAKEOPTS="-j${jobs}" \
        ACCEPT_LICENSE="* -@EULA" \
        GRUB_PLATFORMS="pc efi-64" \
        FEATURES="-news" \
        /bin/bash -lc "$*"
}

mount_chroot() {
    # Use a private tmpfs for /dev. Never bind the host /dev: rm -rf would
    # happily traverse a bind mount and destroy the host's device nodes.
    sudo mkdir -p "$root/dev" "$root/dev/pts" "$root/dev/shm" "$root/proc" "$root/sys"
    sudo mount -t tmpfs -o mode=0755,nosuid tmpfs "$root/dev"
    sudo mkdir -p "$root/dev/pts" "$root/dev/shm"
    sudo mknod -m 666 "$root/dev/null"    c 1 3
    sudo mknod -m 666 "$root/dev/zero"    c 1 5
    sudo mknod -m 666 "$root/dev/full"    c 1 7
    sudo mknod -m 666 "$root/dev/random"  c 1 8
    sudo mknod -m 666 "$root/dev/urandom" c 1 9
    sudo mknod -m 666 "$root/dev/tty"     c 5 0
    sudo mknod -m 620 "$root/dev/console" c 5 1
    sudo mknod -m 666 "$root/dev/ptmx"    c 5 2
    sudo ln -sfn /proc/self/fd   "$root/dev/fd"
    sudo ln -sfn /proc/self/fd/0 "$root/dev/stdin"
    sudo ln -sfn /proc/self/fd/1 "$root/dev/stdout"
    sudo ln -sfn /proc/self/fd/2 "$root/dev/stderr"
    sudo mount -t devpts devpts "$root/dev/pts"
    sudo mount -t tmpfs tmpfs "$root/dev/shm"
    sudo mount --bind /proc "$root/proc"
    sudo mount --bind /sys  "$root/sys"
}

umount_chroot() {
    unmount_under "$root"
}

cleanup() { umount_chroot; }
trap cleanup EXIT

mount_chroot

# ---------------------------------------------------------------------------
log "syncing the package database"
chroot_run "emerge-webrsync --quiet || emerge --sync --quiet || true"

# ---------------------------------------------------------------------------
log "generating overlay manifests"
chroot_run 'cd /var/db/repos/genbox && for e in $(find . -name "*.ebuild"); do ebuild "$e" manifest >/dev/null || exit 1; done'

# ---------------------------------------------------------------------------
log "removing openrc, sysvinit and udev"
chroot_run "emerge --ask=n --unmerge \
    sys-apps/openrc \
    sys-apps/sysvinit \
    sys-fs/udev \
    sys-fs/udev-init-scripts \
    virtual/udev || true"

# ---------------------------------------------------------------------------
if [ "$live_kernel" = "bin" ]; then
    log "merging the live kernel (binary dist-kernel)"
    kernel_pkg="sys-kernel/gentoo-kernel-bin"
else
    log "merging the live kernel (compiled dist-kernel)"
    kernel_pkg="sys-kernel/gentoo-kernel"
fi

log "merging genbox packages and installer tools"
chroot_run "emerge --ask=n --oneshot --update \
    sys-apps/genbox-init \
    virtual/service-manager \
    dev-libs/newt \
    sys-apps/busybox \
    ${kernel_pkg} \
    sys-kernel/linux-firmware \
    sys-block/parted \
    sys-fs/e2fsprogs \
    sys-fs/dosfstools \
    net-misc/wget \
    app-arch/xz-utils \
    sys-apps/pciutils \
    sys-apps/usbutils \
    sys-boot/grub \
    sys-boot/efibootmgr \
    net-misc/dhcpcd \
    app-arch/cpio"

# Ensure /sbin/init points at BusyBox init after the unmerge.
chroot_run "ln -sfn busybox /sbin/init"

# ---------------------------------------------------------------------------
log "installing the genbox make.conf, installer and documentation"
sudo mkdir -p "$root/etc/portage"
sudo cp "$repo/installer/make.conf" "$root/etc/portage/make.conf"
sudo cp "$repo/installer/make.conf" "$root/etc/portage/make.conf.genbox"

sudo mkdir -p "$root/usr/share/doc/genbox"
sudo cp -a "$repo/docs/." "$root/usr/share/doc/genbox/"

if [ -d "$repo/installer" ]; then
    sudo mkdir -p "$root/usr/share/genbox/installer" "$root/usr/sbin"
    sudo cp -a "$repo/installer/." "$root/usr/share/genbox/installer/"
    sudo install -m 0755 "$repo/installer/genbox-installer" "$root/usr/sbin/genbox-installer"
fi

# ---------------------------------------------------------------------------
log "cleaning the chroot"
chroot_run "rm -rf /var/tmp/portage/* /var/tmp/* /tmp/* || true"

touch "$root/.built"
log "rootfs complete: $root"
