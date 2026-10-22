# Installing genbox

This guide walks you through installing genbox onto a disk. It is written for
people who have never installed a Linux system before.

> **Warning:** Installing an operating system erases data. The installer will
> ask you to choose a disk. **That disk will be wiped.** If you are not sure
> which disk to choose, stop and ask for help, or test in a virtual machine
> first (see the last section).

---

## 1. What you need

- A computer with a 64-bit (amd64 / x86-64) processor.
- At least **20 GB** of free disk space (the kernel is compiled, which needs
  room).
- At least **2 GB** of RAM (4 GB or more is comfortable).
- A wired or wireless internet connection. The installer downloads source code.
- A USB stick of 1 GB or more, **or** a virtual machine.

---

## 2. Write the genbox ISO to a USB stick

The genbox installer comes as a single `.iso` file.

### On Linux

```sh
lsblk                       # find your USB stick, e.g. /dev/sdX
sudo dd if=genbox.iso of=/dev/sdX bs=4M status=progress oflag=sync
sync
```

Replace `/dev/sdX` with your USB stick. **Do not add a number** (use
`/dev/sdb`, not `/dev/sdb1`).

### On Windows

Use a tool such as **Rufus** or **balenaEtcher**. Choose "DD mode" if asked.

### On macOS

```sh
diskutil list               # find the disk, e.g. /dev/diskN
diskutil unmountDisk /dev/diskN
sudo dd if=genbox.iso of=/dev/rdiskN bs=1m
```

---

## 3. Boot from the USB stick

1. Insert the USB stick.
2. Restart the computer.
3. During the very first seconds, press the **boot menu** key. This is usually
   **F12**, **F10**, **Esc**, or **F2** (it varies by brand).
4. Choose the USB stick from the list.
5. The genbox boot menu appears. Press **Enter** to boot.
6. After a minute the installer starts automatically on the first console.

> **Need a shell?** genbox also opens a root shell on **tty2**. Switch to it
> with **Ctrl+Alt+F2**. The installer keeps running on tty1 (Ctrl+Alt+F1).

If the computer boots straight into its old system, restart and try a different
boot-menu key. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if you get stuck.

### Secure Boot must be disabled

genbox is a small independent distribution. Its boot loader is **not signed**
with a Microsoft-trusted key, so firmware with **Secure Boot enabled will
refuse to boot the medium** (often shown as *"Access Denied"*, *"Security
Violation"*, or the machine simply returning to the firmware menu).

Before booting the USB stick, enter the firmware setup and **turn Secure Boot
off** (sometimes labelled *"Other OS"*, *"Setup Mode"*, or *"Disable"*).
genbox does not support Secure Boot at this time.

---

## 4. The installer

After a moment, the genbox welcome screen appears. Use:

- **Arrow keys** or **Tab** to move between items.
- **Space** to tick a checkbox.
- **Enter** to confirm.
- **Esc** to go back one step.

The installer asks a series of questions:

### 4.1 Keyboard layout
Pick the layout that matches your keyboard. If you have a US keyboard, keep
the default.

### 4.2 Disk selection
Choose the disk to install onto. **Everything on it will be erased.**

- The installer shows each disk with its size and model.
- Read carefully. Pick the correct one.
- If you see your USB stick in the list, **do not pick it**.

### 4.3 Partitioning
The installer partitions the chosen disk automatically, using GPT:

- a small **BIOS boot** partition (1 MiB), so legacy BIOS machines work,
- a **1 GiB EFI system partition** (FAT32) mounted at `/boot`,
- the **rest of the disk** as the genbox root filesystem (ext4).

This layout boots on both BIOS and UEFI machines. There is no separate swap
partition; genbox uses a swap file if you add one later.

### 4.4 Hostname
A name for this computer on the network, for example `mylaptop`. Use only
letters, numbers, and hyphens.

### 4.5 Timezone
Pick your region and city. This sets the system clock correctly.

### 4.6 Root password
The administrator ("root") password. Choose something you will remember.
You will type it twice. Nothing appears on screen while you type - that is
normal.

### 4.7 User account
A normal, everyday account:

- **Username:** lowercase, no spaces, for example `alex`.
- **Password:** typed twice, nothing shown on screen.
- This user can become root later using the `su` command.

### 4.8 Network
The installer needs internet access to download and compile the kernel. It
starts **NetworkManager** so both wired and wireless networks work:

- **Wired (ethernet):** choose "Connect wired Ethernet"; DHCP is automatic.
- **Wireless (Wi-Fi):** choose "Connect to a Wi-Fi network", pick your SSID,
  and type the password.
- **Test:** use "Test internet access" before continuing.
- **Advanced:** choose "Open the NetworkManager TUI" (or switch to tty2 and
  run `nmtui` / `nmcli`).

The installer refuses to silently continue without a connection: it warns that
the kernel build will fail if there is no internet.

### 4.9 Kernel
The installer offers the **Gentoo distribution kernel**
(`sys-kernel/gentoo-kernel`). It is **compiled from source** on your machine
after installation. This takes time (often 20-60 minutes) but produces a kernel
tuned by the Gentoo kernel team that works on a very wide range of hardware.

> **Why compile?** A distribution kernel built from source gives you the
> Gentoo kernel patches, full control over options, and no reliance on
> someone else's binary. It is the "proper Gentoo way" and it *just works* on
> almost every device.

### 4.10 Confirm
The installer shows a summary. Read it. If everything is correct, choose
**Install**. To change something, go back.

> **This is the point of no return.** The disk will now be erased and genbox
> installed, including downloading and compiling the kernel.

### 4.11 Wait
The installer now:

1. Partitions and formats the disk.
2. Unpacks the genbox system files.
3. Downloads and compiles the kernel (the longest step).
4. Installs the bootloader.
5. Creates your user account.

A progress bar shows what is happening. **Do not remove the USB stick and do
not turn off the computer.**

---

## 5. Finishing

When the installer says it is done:

1. Remove the USB stick.
2. Press Enter to reboot (or restart the computer yourself).
3. You should see the genbox boot messages, then a login prompt.

Continue with **[FIRST-BOOT.md](FIRST-BOOT.md)**.

---

## 6. Trying genbox in a virtual machine first (recommended)

If you are nervous, test in QEMU first. Nothing on your real disk is touched.

```sh
qemu-system-x86_64 \
    -m 4096 \
    -smp 4 \
    -enable-kvm \
    -cdrom genbox.iso \
    -boot d \
    -drive file=genbox-test.img,format=raw,if=virtio
```

Then follow the same steps as above, choosing the virtual disk. When the
installer compiles the kernel, the virtual machine will be busy for a while.
That is normal.

> On Fedora, install QEMU with: `sudo dnf install qemu-kvm`

---

## 7. If something goes wrong

See **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for:

- The computer does not boot from USB.
- No disks are shown in the installer.
- The kernel build fails (often out of disk space or RAM).
- No internet connection in the installer.

You can always restart the installer from the USB stick and try again.
