# How genbox boots

This page explains what happens from the moment you press the power button to
the moment you see a login prompt. It is written in plain language.

---

## The short version

```
Firmware (BIOS/UEFI)
     |
     v
Bootloader (GRUB or isolinux) loads the kernel and initramfs
     |
     v
Kernel starts, mounts the initramfs (a tiny in-memory filesystem)
     |
     v
initramfs finds the genbox system, mounts it, and switch_root
     |
     v
BusyBox init (PID 1) reads /etc/inittab
     |
     v
genbox boot sequence runs runlevels: sysinit -> boot -> default
     |
     v
getty starts; you see the login prompt
```

---

## Step by step

### 1. Firmware

Your computer's BIOS or UEFI runs first. It finds a bootable device (your hard
disk) and loads whatever bootloader is installed.

### 2. Bootloader

The installer puts a bootloader on the disk. It loads two things into memory:

- the **kernel** (`vmlinuz-...`), and
- the **initramfs**, a small compressed filesystem.

It also tells the kernel where the root filesystem is.

### 3. The kernel

The kernel starts, sets up memory and hardware, then runs the first program
inside the initramfs.

### 4. The initramfs

The initramfs is built from BusyBox. It is tiny (a few megabytes) and lives
entirely in RAM. Its job is to:

1. Load any drivers needed to see the real root disk.
2. Mount the real root filesystem.
3. Hand control over with `switch_root`.
4. Disappear.

genbox builds its own initramfs; it does not use a generator like `dracut`.

### 5. BusyBox `init` takes over as PID 1

**PID 1** is the very first process on a Linux system. Everything else is its
child. genbox uses BusyBox `init` as PID 1 - it is small, simple, and reads a
plain text file.

That file is `/etc/inittab`:

```
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::sysinit:/sbin/openrc default
::respawn:/sbin/getty 38400 tty1
::respawn:/sbin/getty 38400 tty2
::respawn:/sbin/getty 38400 tty3
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/openrc shutdown
::restart:/sbin/init
```

| Action | Meaning |
| --- | --- |
| `sysinit` | Run once, at the very start, and wait for it. |
| `respawn` | Run it, and restart it if it ever exits. |
| `ctrlaltdel` | Run this when you press Ctrl+Alt+Del. |
| `shutdown` | Run this when the system powers off. |
| `restart` | Run this to reboot. |

### 6. The genbox boot sequence

BusyBox `init` runs `/sbin/openrc` once per runlevel, in order:

```
sysinit  ->  boot  ->  default
```

Within each runlevel, services start in the order their `depend()` functions
request. This is the same idea as OpenRC, just with genbox's own engine.

### 7. getty and login

Once the `default` runlevel is up, BusyBox `init` starts `getty` on each
virtual console. `getty` prints the login prompt and waits for you to type your
username and password.

---

## Shutting down

When you run `poweroff` or `reboot`:

1. The `shutdown` runlevel runs, stopping services in reverse order.
2. Filesystems are unmounted read-only or remounted read-only.
3. The kernel tells the hardware to power off or reboot.

The `shutdown` action in `/etc/inittab` runs `/sbin/openrc shutdown`, which
performs the service shutdown.

---

## Runlevels explained

A **runlevel** is just a directory full of symlinks:

```
/etc/runlevels/sysinit/
/etc/runlevels/boot/
/etc/runlevels/default/
/etc/runlevels/shutdown/
/etc/runlevels/nonetwork/
```

Each symlink points at a script in `/etc/init.d/`:

```
/etc/runlevels/default/sshd -> /etc/init.d/sshd
```

`rc-update add sshd default` simply creates that symlink.
`rc-update del sshd default` removes it.

---

## What is different from OpenRC?

| | OpenRC | genbox |
| --- | --- | --- |
| PID 1 | OpenRC's `init` | BusyBox `init` |
| Boot trigger | OpenRC reads its own config | `/etc/inittab` `sysinit` action |
| Service engine | OpenRC | genbox's own engine |
| Service scripts | `/etc/init.d` OpenRC dialect | same dialect |
| Commands | `rc-service`, `rc-update` | same commands |

If you have used Gentoo with OpenRC before, almost everything looks the same.
The service scripts, the runlevels, and the commands all match. What is
different is what runs *underneath*.

---

## Debugging a boot problem

- Watch the messages: genbox prints `[ ok ]` / `[ !! ]` for each service.
- If the boot stops early, look for the last `[ !! ]` line.
- A failing `sysinit` service can stop everything after it.
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for recovery.
