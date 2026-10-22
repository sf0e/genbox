# Changelog

All notable changes to genbox are documented here.

## [0.1.1] - 2026-10-22

### Fixed
- Live ISO boot: corrected console ordering (`tty0` first), added a safe-video
  boot entry, longer GRUB timeout, and a diagnostic rescue shell.
- UEFI: documented that Secure Boot must be disabled and that Q35 is required
  for UEFI virtual machines.
- Installed system: root is mounted read-write, `/run` is a clean tmpfs, and
  `/etc/mtab` exists; the installed GRUB menu uses the same reliable console
  ordering.
- Installer: fixed the disk menu (entries are paired correctly, floppy/loop
  devices are hidden), fixed the tty2/serial rescue shells, and made the
  network step part of the installer.

### Added
- **NetworkManager**, **`nmcli`**, **`nmtui`**, `wpa_supplicant`, `iw`,
  `wireless-regdb`, and Wi-Fi firmware.
- A **coldplug** service that loads kernel modules for every present device
  (PCI/USB modalias), including wired and wireless network adapters.
- Installer network screen: wired auto-connect, Wi-Fi scan and password,
  hidden SSIDs, connection test, and an "Open nmtui" option.
- The installed system enables `dbus` and `NetworkManager`; Wi-Fi profiles
  created during installation are carried over.
- A kernel config fragment that disables debug/KUnit/UBSAN options so the
  installer builds a practical distribution kernel.

### Notes
- Secure Boot is still unsupported; disable it in firmware to boot genbox.
- The live medium uses `sys-kernel/gentoo-kernel-bin`; the installer compiles
  `sys-kernel/gentoo-kernel` for the installed system.

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
