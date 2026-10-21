#!/bin/bash
# finalize-rootfs.sh - refresh the overlay, reinstall genbox-init, and copy the
# installer/documentation into an existing build/rootfs.
#
# Usage: sudo GENBOX_REUSE_ROOTFS=1 scripts/finalize-rootfs.sh [root-dir] [repo-dir]
#
# Safe to run repeatedly. Used during development after editing the overlay.
set -euo pipefail

root="$(readlink -f "${1:-build/rootfs}")"
repo="$(readlink -f "${2:-.}")"

log() { printf '\n==> %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "error: run as root (sudo)" >&2; exit 1; }
[ -x "$root/bin/bash" ] || { echo "error: $root is not a rootfs" >&2; exit 1; }

mounts_under() {
    local d="$1"
    awk -v d="$d" '$2 == d || index($2, d "/") == 1 { print $2 }' /proc/mounts
}

unmount_under() {
    local d="$1"
    mounts_under "$d" | tac | while read -r m; do
        [ -n "$m" ] && umount -l "$m" 2>/dev/null || true
    done || true
}

mount_chroot() {
    mkdir -p "$root/dev" "$root/dev/pts" "$root/dev/shm" "$root/proc" "$root/sys"
    mount -t tmpfs -o mode=0755,nosuid tmpfs "$root/dev"
    mkdir -p "$root/dev/pts" "$root/dev/shm"
    mknod -m 666 "$root/dev/null"    c 1 3
    mknod -m 666 "$root/dev/zero"    c 1 5
    mknod -m 666 "$root/dev/full"    c 1 7
    mknod -m 666 "$root/dev/random"  c 1 8
    mknod -m 666 "$root/dev/urandom" c 1 9
    mknod -m 666 "$root/dev/tty"     c 5 0
    mknod -m 620 "$root/dev/console" c 5 1
    mknod -m 666 "$root/dev/ptmx"    c 5 2
    ln -sfn /proc/self/fd   "$root/dev/fd"
    ln -sfn /proc/self/fd/0 "$root/dev/stdin"
    ln -sfn /proc/self/fd/1 "$root/dev/stdout"
    ln -sfn /proc/self/fd/2 "$root/dev/stderr"
    mount -t devpts devpts "$root/dev/pts"
    mount -t tmpfs tmpfs "$root/dev/shm"
    mount --bind /proc "$root/proc"
    mount --bind /sys  "$root/sys"
}

chroot_run() {
    chroot "$root" /usr/bin/env -i \
        HOME=/root TERM="${TERM:-linux}" \
        PATH=/usr/sbin:/usr/bin:/sbin:/bin \
        MAKEOPTS="-j${JOBS:-$(nproc)}" \
        ACCEPT_LICENSE="* -@EULA" \
        GRUB_PLATFORMS="pc efi-64" \
        FEATURES="-news" \
        /bin/bash -lc "$*"
}

cleanup() { unmount_under "$root"; }
trap cleanup EXIT

mount_chroot

log "refreshing the overlay from $repo/overlay"
rm -rf "$root/var/db/repos/genbox"
cp -a "$repo/overlay" "$root/var/db/repos/genbox"

log "regenerating manifests"
chroot_run 'cd /var/db/repos/genbox && for e in $(find . -name "*.ebuild"); do ebuild "$e" manifest >/dev/null || exit 1; done'

log "reinstalling genbox-init and the service-manager virtual"
chroot_run "emerge --ask=n --unmerge sys-apps/genbox-init || true"
chroot_run "emerge --ask=n --oneshot --noreplace \
    sys-apps/genbox-init \
    virtual/service-manager \
    dev-libs/newt \
    sys-boot/grub \
    sys-boot/efibootmgr \
    net-misc/dhcpcd \
    app-arch/cpio"

log "copying make.conf, installer and documentation"
mkdir -p "$root/etc/portage" "$root/usr/share/doc/genbox" "$root/usr/sbin" \
         "$root/usr/share/genbox/installer"
cp "$repo/installer/make.conf" "$root/etc/portage/make.conf"
cp "$repo/installer/make.conf" "$root/etc/portage/make.conf.genbox"
cp -a "$repo/docs/." "$root/usr/share/doc/genbox/"
cp -a "$repo/installer/." "$root/usr/share/genbox/installer/"
install -m 0755 "$repo/installer/genbox-installer" "$root/usr/sbin/genbox-installer"

log "fixing /sbin/init"
ln -sfn busybox "$root/sbin/init"

log "done"
