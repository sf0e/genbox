# genbox architecture

This page is for people curious about **how genbox is built** and **how to
build it yourself**. It is more technical than the other documents.

---

## Overview

genbox is a Gentoo stage3 that has been transformed:

```
Gentoo stage3 (openrc)
        |
        |  (1) add the genbox overlay
        |  (2) apply the genbox profile
        |  (3) emerge sys-apps/genbox-init
        |  (4) unmerge openrc, sysvinit, udev
        |  (5) switch /sbin/init to BusyBox init
        v
genbox root filesystem
        |
        |  (6) pack a squashfs OR tarball
        |  (7) build a BusyBox initramfs
        |  (8) assemble the ISO with xorriso
        v
genbox.iso
```

---

## The overlay

An **overlay** is an extra package repository that sits alongside Gentoo's. The
genbox overlay provides:

| Package | Purpose |
| --- | --- |
| `sys-apps/genbox-init` | the service manager, `openrc-run`, `rc-service`, ... |
| `virtual/service-manager` | overridden so OpenRC is never pulled in |
| `profiles/genbox/...` | USE flags, package masks, and defaults |

Because `virtual/service-manager` normally depends on `sys-apps/openrc`, genbox
ships a **newer revision** of that virtual whose only provider is
`sys-apps/genbox-init`. Portage always prefers the newest revision, so OpenRC
is silently replaced.

---

## The genbox service manager

Everything lives under `/usr/libexec/genbox/`:

```
/usr/libexec/genbox/
  sh/
    functions.sh        the ebegin/eend/einfo/... output helpers
    rc-functions.sh     service state helpers (started/stopped/...)
    openrc-run.sh       the script dispatcher
    start-stop-daemon.sh  default start/stop/status for command= services
    supervise-daemon.sh   supervisor= support
    gendepends.sh       extract depend() information
  bin/
    ebegin, eend, einfo, ... (thin wrappers, so `command ebegin` works)
    checkpath
```

And the public commands:

```
/sbin/openrc-run        run a service script
/sbin/rc-service        control a service
/sbin/rc-update         manage runlevels
/sbin/rc-status         show status
/sbin/openrc            run a runlevel
/sbin/openrc            run one runlevel
/sbin/openrc-init       optional helper that runs all levels
/sbin/openrc-shutdown   power-off helper
/sbin/start-stop-daemon our own start/stop tool
```

### Byte-compatible output

The `ebegin`/`eend`/`einfo` family prints exactly the same bytes as OpenRC's
C library in non-terminal mode. This was verified by capturing OpenRC's output
with `od -c` and comparing, byte for byte, including the padding that aligns
the `[ ok ]` marker to column 80.

This means any script that checks for `[ ok ]` or parses the output keeps
working.

### The `/sbin/openrc-run` contract

genbox reproduces OpenRC's calling convention:

```
openrc-run <script> [options] <command> [args]
```

- Options come **after** the script path.
- The script is loaded, config from `/etc/conf.d/` is applied, then the
  requested command function is called.
- `depend()` output is collected through a file descriptor, exactly as OpenRC
  does.

---

## Boot chain

| File | Role |
| --- | --- |
| `/etc/inittab` | BusyBox init's instruction list |
| `/sbin/init` | a symlink to BusyBox, so BusyBox `init` is PID 1 |
| `/sbin/openrc` | runs one runlevel (sysinit, boot, default, shutdown) |
| `/sbin/openrc-init` | optional helper that runs all levels in order |
| `/sbin/openrc-shutdown` | stopped-services helper used by poweroff |

---

## Device management

genbox uses **BusyBox `mdev`** instead of `udev`:

- `mdev -s` scans `/sys` at boot and creates the right `/dev` entries.
- A hotplug line (`echo /sbin/mdev > /proc/sys/kernel/hotplug`) handles devices
  added later.
- There is no daemon, no database, and no persistent state - just a rule that
  creates device nodes on demand.

The `mdev` service lives in `/etc/init.d/mdev`.

---

## Building the ISO

The `Makefile` drives everything:

```sh
make stage3      # download and extract the Gentoo stage3
make rootfs      # chroot in, apply overlay+profile, emerge genbox
make initramfs   # build the BusyBox initramfs
make iso         # assemble dist/genbox.iso with xorriso
make test        # boot the ISO in QEMU
make clean       # remove build artifacts
```

### Build host requirements

Any modern Linux with:

- `sudo`
- `make`
- `wget` or `curl`
- `tar`, `xz`
- `cpio`
- `xorriso` and `grub2-mkrescue` + `mtools` (for the ISO)
- `mksquashfs` (from `squashfs-tools`)
- `qemu-system-x86_64` (only for `make test`)
- about **20 GB** of free disk space

On Fedora:

```sh
sudo dnf install make xorriso grub2-tools mtools cpio squashfs-tools \
    qemu-kvm wget tar xz
```

On Debian/Ubuntu:

```sh
sudo apt install make xorriso grub-pc-bin grub-efi-amd64-bin mtools cpio \
    squashfs-tools qemu-system-x86 wget tar xz-utils
```

### What `make rootfs` does

1. Downloads the Gentoo stage3 tarball.
2. Extracts it into `root/`.
3. Copies the genbox overlay into `/var/db/repos/genbox`.
4. Writes `repos.conf` so Portage knows about the overlay.
5. Points the profile at `genbox:genbox/linux/amd64`.
6. `emerge`s `sys-apps/genbox-init` and BusyBox (Whiptail comes from `dev-libs/newt`).
7. Unmerges `openrc`, `sysvinit`, `udev`.
8. Installs the installer and the documentation.

### What `make initramfs` does

Builds a BusyBox initramfs whose `init` script:

1. Mounts `/proc`, `/sys`, `/dev`.
2. Finds the genbox root filesystem on the ISO.
3. Mounts it and `switch_root`s into it.

---

## The installer

The installer is a set of shell scripts run inside a Whiptail text UI:

```
installer/
  genbox-installer       main entry point
  lib/                   helper functions
  steps/                 one file per installer screen
  make.conf              the pre-made, documented make.conf
```

It:

1. Asks for language, keyboard, disk, hostname, timezone, passwords, network.
2. Partitions and formats the chosen disk.
3. Unpacks the root filesystem.
4. Configures the base system (fstab, hostname, users, timezone).
5. Emerges and **compiles** `sys-kernel/gentoo-kernel`.
6. Installs the bootloader.

---

## Why compile the kernel?

The installer builds `sys-kernel/gentoo-kernel` from source because:

- It is the Gentoo distribution kernel, maintained and patched by Gentoo.
- It works on a very wide range of hardware out of the box.
- Building from source is the "Gentoo way" and gives you a kernel you own.
- Config changes are possible later via `/etc/kernel/config.d/`.

The trade-off is time: expect tens of minutes depending on your CPU.

> The **live ISO** uses a prebuilt distribution kernel
> (`sys-kernel/gentoo-kernel-bin`) so that it boots quickly and reliably on
> the widest range of hardware. The kernel that ends up on **your disk** is
> always compiled from source by the installer (`sys-kernel/gentoo-kernel`).

---

## Tests

`tests/` contains small scripts that:

- Compare genbox's `e*` output against captured OpenRC output.
- Start and stop a real service and check the state changes.
- Exercise `start-stop-daemon` with a simple daemon.

Run them with `make check`.
