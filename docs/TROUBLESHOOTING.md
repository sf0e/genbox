# Troubleshooting

Something went wrong. This page lists the most common problems and how to fix
them. Find your symptom and follow the steps.

---

## The computer will not boot from the USB stick

**Symptoms:** The old operating system starts anyway, or the boot menu does not
list the USB stick.

**Fixes:**

1. Restart and press the boot-menu key **repeatedly** during the first few
   seconds. Common keys: **F12**, **F10**, **F9**, **Esc**, **F2**.
2. Enter the firmware setup (usually **Del** or **F2**) and check:
   - The USB stick is detected.
   - **Secure Boot** is disabled or set to "Other OS".
   - **USB boot** is enabled.
3. Re-write the ISO to the stick, and this time use **DD mode** if the tool
   offers it.
4. Try a different USB port, preferably a USB 2.0 port on older machines.
5. Try a different USB stick; some are not bootable.

---

## The installer shows no disks

**Symptoms:** The disk list is empty.

**Fixes:**

1. Your disk controller may need a driver that the installer cannot load.
   In a virtual machine, switch the disk to a simpler bus (IDE or SATA instead
   of a passthrough/virtio-scsi setup).
2. Check the disk is visible to the firmware (it should appear in the BIOS).
3. If the disk is part of a RAID array, break the array or configure it in the
   firmware first.

---

## The installer has no internet

**Symptoms:** Downloads fail, or "cannot reach mirror".

**Fixes:**

1. For Wi-Fi, confirm the password. Passwords are case-sensitive.
2. Try a wired connection - it is the most reliable.
3. Check the cable and the router lights.
4. If you use a captive portal (hotel, airport), it may not work from the
   installer.
5. Try again: mirrors are sometimes briefly unavailable.

---

## The kernel build fails

**Symptoms:** The installation stops during "compiling the kernel", or a build
error mentions "Killed" or "No space left".

### "Killed" or the machine freezes

You ran out of **memory**. Each parallel compile job needs RAM.

Fix after install (or during, if the installer offers a retry):

```sh
su -
nano /etc/portage/make.conf
# change: MAKEOPTS="-j1"
# and:    EMERGE_DEFAULT_OPTS="--ask --jobs=1"
emerge --ask sys-kernel/gentoo-kernel
```

### "No space left on device"

You ran out of **disk space**. The kernel build needs several gigabytes.

- Free space: `emerge --ask --depclean` and `eclean-dist`.
- Or reinstall with a larger partition.

### Other build errors

- Read the last 20 lines of the error - it usually names the failing step.
- Ensure `/etc/portage/make.conf` has not been edited incorrectly. Restore it:
  ```sh
  cp /etc/portage/make.conf.genbox /etc/portage/make.conf
  ```
- Update the package list and retry:
  ```sh
  emerge --sync
  emerge --ask sys-kernel/gentoo-kernel
  ```

---

## The system boots but stops at a `[ !! ]` line

**Symptoms:** Boot stops, or a service fails.

**Fixes:**

1. Note **which service** failed (the text right before `[ !! ]`).
2. At a rescue prompt (or after logging in):
   ```sh
   rc-service <name> start
   ```
   and read the error.
3. Check the service's configuration in `/etc/conf.d/<name>`.
4. Many `[ !! ]` messages are harmless (for example, a service already
   running). If the system reaches a login prompt, it is likely fine.

---

## I cannot log in

**Symptoms:** The password is rejected.

**Fixes:**

1. Passwords are **case-sensitive**, and nothing shows while typing.
2. Check the keyboard layout. If you picked the wrong one, some symbols type
   differently.
3. If you forgot the root password, boot the ISO again and use the installer's
   rescue mode to reset it (or chroot into the installed system and run
   `passwd`).

---

## Wi-Fi does not work after install

**Fixes:**

1. Install firmware:
   ```sh
   su -
   emerge --ask sys-kernel/linux-firmware
   ```
2. Start the services:
   ```sh
   rc-update add wpa_supplicant default
   rc-service wpa_supplicant start
   rc-update add dhcpcd default
   rc-service dhcpcd start
   ```
3. Check the interface name:
   ```sh
   ip addr
   ```
4. Confirm your network is configured in `/etc/conf.d/`.

---

## "command not found" for `nano`, `equery`, etc.

Those are separate packages. Install them:

```sh
su -
emerge --ask app-editors/nano
emerge --ask app-portage/gentoolkit
```

---

## A package fails with a USE flag conflict

**Symptoms:** `The following REQUIRED_USE flag constraints are unsatisfied`.

**Fixes:**

1. Read the suggested solution Portage prints - it usually names the exact
   flags to set.
2. Set them per-package in `/etc/portage/package.use`:
   ```sh
   su -
   echo "category/package flag1 -flag2" >> /etc/portage/package.use
   ```
3. Retry the install.

---

## I edited `make.conf` and now builds fail

Restore the pre-made file:

```sh
su -
cp /etc/portage/make.conf.genbox /etc/portage/make.conf
emerge --ask --changed-use --update @world
```

---

## Nothing here helped

1. Note what you did, what you expected, and what happened.
2. Capture the exact error message.
3. Open an issue on the project's GitHub page with those details.
4. Include the output of:
   ```sh
   uname -a
   cat /etc/portage/make.conf
   rc-status
   ```

---

## Emergency: get a root shell from the installer

1. Boot the genbox ISO.
2. At the boot menu, choose the "rescue shell" entry if available.
3. Or, once booted, the installer's first screen usually offers a shell.

From there you can mount your installed system and fix it:

```sh
mkdir -p /mnt/genbox
mount /dev/sda3 /mnt/genbox      # use your real root partition
mount /dev/sda1 /mnt/genbox/boot # if you have a separate /boot
mount --bind /dev  /mnt/genbox/dev
mount --bind /proc /mnt/genbox/proc
mount --bind /sys  /mnt/genbox/sys
chroot /mnt/genbox /bin/sh
```

Now you are "inside" your installed system and can fix files, reset passwords,
or reinstall the bootloader.
