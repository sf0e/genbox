# Glossary

Every term used in the genbox documentation, in plain language, alphabetical.

---

**amd64** - the 64-bit processor architecture used by Intel and AMD desktop
and server CPUs. Also called "x86-64" or "x64". genbox targets this
architecture.

**BIOS** - the old-style firmware that starts a computer. See also UEFI.

**Bootloader** - the small program that loads the kernel. genbox uses GRUB on
installed systems and isolinux on the ISO.

**BusyBox** - a single small program that provides many classic Unix tools
(`ls`, `mount`, `init`, and more). genbox uses it for `init` and `mdev`.

**chroot** - running a program with a different directory pretending to be the
root (`/`). The installer and build process use it to work inside the target
system.

**conf.d** - `/etc/conf.d/`, a directory of small files that configure
individual services (for example the hostname or network).

**dist-kernel** - a "distribution kernel", a kernel configured and patched by
the distribution. genbox installs the Gentoo dist-kernel
(`sys-kernel/gentoo-kernel`) and compiles it.

**ebegin / eend / einfo** - helper commands in init scripts that print the
` * message ...` and `[ ok ]` / `[ !! ]` lines. genbox reproduces their output
byte for byte.

**emerge** - Gentoo's package manager command. It downloads, compiles, and
installs software.

**firmware** - software stored in hardware that runs before the operating
system. Also used for `/lib/firmware` device files (like Wi-Fi firmware).

**getty** - the program that shows the `login:` prompt and starts a user
session.

**GRUB** - a common bootloader. genbox uses it on installed systems.

**init** - the very first program the kernel runs (process ID 1). genbox uses
BusyBox `init`, which reads `/etc/inittab`.

**initramfs** - a tiny filesystem loaded into memory at boot, used to find and
mount the real root filesystem. genbox builds its own with BusyBox.

**inittab** - `/etc/inittab`, the plain text file BusyBox `init` reads to know
what to run and when.

**isolinux** - the bootloader used on the genbox ISO.

**kernel** - the core of the operating system: it talks to hardware and manages
memory, processes, and files. genbox compiles it during installation.

**mdev** - BusyBox's small device manager. It creates `/dev` entries from
`/sys`. Replaces `udev` in genbox.

**overlay** - an extra package repository that sits next to Gentoo's. The
genbox overlay provides its packages, profile, and the replacement for OpenRC.

**PID 1** - process ID 1, the first process on the system, parent of all
others. See **init**.

**Portage** - Gentoo's package manager (the software behind `emerge`).

**profile** - a set of default settings (USE flags, package masks) for a type
of system. genbox ships `genbox/linux/amd64`.

**root** - (1) the administrator account; (2) `/`, the top of the filesystem.

**rootfs** - the root filesystem: the whole installed system.

**runlevel** - a named group of services that start together, such as `boot` or
`default`. Stored as directories of symlinks under `/etc/runlevels/`.

**service** - a program that runs in the background, like networking or SSH.

**squashfs** - a compressed, read-only filesystem format. Often used for live
ISOs.

**stage3** - Gentoo's base system tarball. genbox starts from a stage3 and
modifies it.

**switch_root** - the step where the initramfs hands control to the real root
filesystem.

**sysinit** - the earliest runlevel; sets up devices and filesystems before
anything else.

**systemd** - a large, complex init and service system used by many distros.
genbox does **not** use it.

**UEFI** - modern firmware that replaces BIOS and supports modern boot methods.

**udev** - the standard Linux device manager. genbox replaces it with `mdev`.

**USE flags** - names that turn optional features of packages on (plain) or off
(prefixed with `-`). Set globally in `make.conf`.

**Whiptail** - the library that draws the installer's text-based dialog boxes
and menus.

**xorriso** - the tool that assembles the genbox ISO file.
