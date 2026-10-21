# Changelog

All notable changes to genbox are documented here.

## [0.1.0] - 2026-10-21

First public release.

### Added

- **Boot with BusyBox `init` as PID 1.** `/etc/inittab` runs the genbox
  runlevels (`sysinit`, `boot`, `default`) and starts the console gettys.
- **genbox service manager** — an independent, OpenRC-dialect-compatible
  implementation:
  - `/sbin/openrc-run`, `/sbin/rc-service`, `/sbin/rc-update`,
    `/sbin/rc-status`, `/sbin/openrc`, `/sbin/openrc-shutdown`
  - byte-compatible `ebegin`/`eend`/`einfo`/`ewarn`/`eerror`/`eindent`
    output, including the 80-column `[ ok ]` alignment
  - dependency keywords (`need`, `use`, `want`, `before`, `after`, `provide`)
  - `start-stop-daemon`, `supervise-daemon`, `required_dirs`,
    `required_files`, `checkpath`, `fstabinfo`, `mountinfo`, `kill_all`
  - the base Gentoo `/etc/init.d` scripts work unchanged
- **`mdev` device management** instead of `udev`.
- **Whiptail text installer** that partitions a disk, installs the system,
  creates users, and **compiles `sys-kernel/gentoo-kernel`** for the target.
- **Hybrid BIOS + UEFI ISO** (GRUB, built for `pc` and `efi-64`).
- **BusyBox live initramfs** with a writable overlay, automatic medium
  detection, and a rescue shell.
- **A pre-made, portable `/etc/portage/make.conf`**, heavily commented and
  safe on desktops, laptops, servers, and virtual machines.
- **Documentation** for installing, first boot, editing `make.conf`, services,
  boot, architecture, troubleshooting, and a glossary.
- **Makefile-driven build**: `make stage3`, `make rootfs`, `make initramfs`,
  `make iso`, `make test`, `make check`.

### Notes

- The live ISO uses `sys-kernel/gentoo-kernel-bin` so it boots quickly and on
  a wide range of hardware. The kernel installed on disk is always compiled
  from source (`sys-kernel/gentoo-kernel`).
- amd64 only.
- The 0.1.0 image was boot-tested under QEMU/KVM (BIOS boot); the runlevels,
  the service manager, and the Whiptail installer UI were verified.

[0.1.0]: https://github.com/sf0e/genbox/releases/tag/v0.1.0
