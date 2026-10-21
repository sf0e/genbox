# Frequently asked questions

## General

### What is genbox?

A small Linux distribution based on Gentoo, with OpenRC removed and replaced by
genbox's own service manager. It boots with BusyBox `init`, manages devices
with `mdev`, and installs with a friendly text installer.

### Is genbox a fork of Gentoo?

No. It *uses* Gentoo - the packages, the package manager (Portage), and the
base system (stage3) all come from Gentoo. genbox adds its own service layer
and profile on top.

### Why not just use Gentoo?

Gentoo is excellent but has a steeper learning curve and a longer install. genbox
aims to be *"Gentoo with training wheels"*: same power underneath, friendlier
install, and documentation written for normal people.

### Why remove OpenRC?

To keep things small and easy to understand. genbox replaces it with a service
manager that is a few shell scripts you can read in an afternoon, while keeping
the exact same commands and script format so packages still work.

### Does genbox use systemd?

No.

### Is it stable enough for daily use?

It is a young project. Test it in a virtual machine first, and do not use it for
anything you cannot afford to lose until you are comfortable.

---

## Installing

### How much disk space do I need?

Around 20 GB. The kernel is compiled, which needs room for source and build
files.

### How long does installation take?

It depends on your CPU, but the kernel compile is the slow part. Expect roughly
20-60 minutes on a typical machine.

### Do I need internet during install?

Yes. The installer downloads source code, including the kernel.

### Can I install without compiling a kernel?

The genbox installer compiles `sys-kernel/gentoo-kernel`. If you want to skip
that, you can build your own kernel afterwards and install it manually, but the
supported path compiles the dist-kernel.

### Can I dual-boot with another operating system?

The installer uses a whole disk and does not offer manual partitioning yet.
Dual-booting currently means installing genbox first and then adding the other
system's bootloader entry by hand, so it is for advanced users.

---

## Using the system

### Where is my configuration?

| What | Where |
| --- | --- |
| Package building | `/etc/portage/make.conf` |
| Services | `/etc/init.d/` and `/etc/conf.d/` |
| Boot services | `/etc/runlevels/` |
| Boot process | `/etc/inittab` and `/sbin/openrc-init` |

### How do I update everything?

```sh
su -
emerge --sync
emerge --ask --update @world
```

### How do I install software?

```sh
su -
emerge --ask <packagename>
```

### How do I become root?

```sh
su -
```

### How do I start a service?

```sh
su -
rc-service <name> start
```

### How do I make a service start at boot?

```sh
su -
rc-update add <name> default
```

### My package failed to build. What now?

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md). Common causes are out of memory,
out of disk space, or a missing `make.conf` setting.

---

## make.conf

### Do I need to edit make.conf?

No. The pre-made file works on almost every device.

### I edited make.conf and things broke. How do I undo it?

```sh
su -
cp /etc/portage/make.conf.genbox /etc/portage/make.conf
```

### What is `-march=native` and should I use it?

It tunes code for your exact CPU model. It is faster but *not portable* -
binaries will not run on other machines. It is safe if you only ever build for
this one computer.

### Why is `MAKEOPTS="-j4"` and not higher?

4 is a safe default that works even on modest machines. Increase it if you have
a fast CPU and plenty of RAM.

---

## Services

### Are OpenRC service scripts supported?

Yes. genbox reads the same `/etc/init.d` scripts. Most packages work unchanged.

### Is this actually OpenRC?

No. It is an independent implementation that speaks the same language. There is
no OpenRC code installed.

### How do services start at boot?

BusyBox `init` runs `/sbin/openrc-init`, which runs the `sysinit`, `boot`, and
`default` runlevels in order.

### Where are logs?

Traditionally in `/var/log/`. Install a syslog service if you want persistent
logs.

---

## Hardware

### Will genbox work on my laptop / desktop / server / VM?

It targets 64-bit amd64 machines and works in QEMU, VirtualBox, and VMware. The
compiled distribution kernel supports a very wide range of hardware.

### Does it support Wi-Fi?

Yes, with the right firmware. Install the firmware packages you need, for
example `sys-kernel/linux-firmware`, then use `wpa_supplicant` and `dhcpcd`.

### Does it support NVIDIA graphics?

Yes. The distribution kernel plus `x11-drivers/nvidia-drivers` (proprietary) or
`nouveau` (open source). Set `VIDEO_CARDS` accordingly.

### What about ARM or RISC-V?

Only amd64 is supported at this time.

---

## Project

### How do I report a bug?

Open an issue on the project's GitHub page.

### Can I contribute?

Yes. Documentation, testing, and bug reports are all valuable. See the
repository README.

### What license is genbox under?

BSD-2-Clause, a permissive open-source license.

### Where can I read more?

Start with the [README](../README.md) documentation map.
