# genbox

**genbox** is a small, friendly Linux distribution built on top of a Gentoo
stage3. It replaces OpenRC with its own lightweight service manager, uses
**BusyBox `init`** as process 1, and ships a **Whiptail text installer** that
compiles a Gentoo distribution kernel for your machine.

Think of it as *"Gentoo, but simpler to install and easier to understand."*

```
        +--------------------------------------------------+
        |                    genbox ISO                    |
        |                                                  |
        |   BusyBox initramfs  ->  mounts rootfs  -> boot  |
        |   BusyBox init (PID 1)                           |
        |   genbox service manager (OpenRC-compatible)     |
        |   Whiptail installer  ->  installs to disk       |
        |   Portage + pre-made make.conf                   |
        |   sys-kernel/gentoo-kernel  (compiled for you)   |
        +--------------------------------------------------+
```

---

## Start here

If you just want to install genbox, read these in order:

1. **[docs/INSTALL.md](docs/INSTALL.md)** – install genbox onto a disk.
2. **[docs/FIRST-BOOT.md](docs/FIRST-BOOT.md)** – what to do the first time you boot.
3. **[docs/EDITING-MAKE-CONF.md](docs/EDITING-MAKE-CONF.md)** – tune the build for your device.

The rest of the docs explain how everything works, in plain language.

---

## Documentation map

| Document | What it explains |
| --- | --- |
| [docs/INSTALL.md](docs/INSTALL.md) | Installing genbox to a disk, step by step |
| [docs/FIRST-BOOT.md](docs/FIRST-BOOT.md) | Your first boot, logins, and basic setup |
| [docs/EDITING-MAKE-CONF.md](docs/EDITING-MAKE-CONF.md) | How to edit `make.conf` for your own device |
| [docs/MAKE-CONF-REFERENCE.md](docs/MAKE-CONF-REFERENCE.md) | Every `make.conf` setting, explained simply |
| [docs/SERVICES.md](docs/SERVICES.md) | Starting, stopping, enabling services |
| [docs/BOOT.md](docs/BOOT.md) | How genbox boots, from firmware to login |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How genbox is built internally |
| [docs/FAQ.md](docs/FAQ.md) | Common questions and answers |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | When something goes wrong |
| [docs/GLOSSARY.md](docs/GLOSSARY.md) | Every term used, in one place |
| [CHANGELOG.md](CHANGELOG.md) | What changed in each release |

---

## What makes genbox different?

- **No OpenRC.** genbox ships its own service manager. It understands the same
  `/etc/init.d` scripts (the "OpenRC dialect"), so most Gentoo packages work
  unchanged, but there is no OpenRC installed anywhere.
- **BusyBox `init` is PID 1.** The smallest practical init, easy to read and
  audit.
- **`mdev` instead of `udev`.** Device nodes are handled by BusyBox `mdev`,
  which is tiny and has no daemon or database.
- **A pre-made `make.conf`.** A single, heavily commented file that works on
  almost any machine and is easy for a person to edit.
- **A compiler-friendly installer.** The installer builds
  `sys-kernel/gentoo-kernel` (the Gentoo distribution kernel) from source for
  your hardware.

---

## Quick facts

| Thing | Value |
| --- | --- |
| Base | Gentoo stage3 (amd64, OpenRC stage3 used only as a starting point) |
| init | BusyBox `init` |
| Service manager | genbox (OpenRC-compatible CLI) |
| Device manager | BusyBox `mdev` |
| Kernel | `sys-kernel/gentoo-kernel` (compiled by the installer; the live medium uses a prebuilt kernel) |
| Installer | Whiptail (text user interface) |
| License | BSD-2-Clause |

---

## Repository layout

```
genbox/
  Makefile              build the ISO (rootfs -> initramfs -> iso)
  docs/                 the documentation you are reading
  overlay/              the genbox Gentoo overlay (packages + profile)
    sys-apps/genbox-init/   the service manager package
    virtual/service-manager/ the virtual that replaces OpenRC
    profiles/               the genbox profile (USE flags, masks)
  installer/            Whiptail installer scripts and assets
  scripts/              helper scripts used by the Makefile
  tests/                small test scripts
```

---

## Building genbox yourself

You need a Linux build host with the tools listed in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Then:

```sh
make            # builds dist/genbox.iso
make test       # boots the ISO in QEMU (if qemu is installed)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full pipeline.
