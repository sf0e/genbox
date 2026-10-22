# Your first boot

You installed genbox and it rebooted. This page tells you what to do next.

---

## 1. Log in

You will see something like:

```
genbox 7.x.x-gentoo-dist
mylaptop login:
```

Type your **username** (the one you created in the installer), press Enter,
then type your **password** and press Enter.

> Nothing appears on screen while you type your password. That is normal and
> is a security feature.

If you need administrator rights, become root with:

```sh
su -
```

(Enter the **root** password you set in the installer.)

---

## 2. Look around

A few commands to try:

```sh
hostname                 # the name you gave this computer
ip addr                  # your network addresses
uname -a                 # which kernel you are running
df -h                    # free disk space
free -h                  # memory usage
```

---

## 3. Check that services are running

genbox has its own service manager. See what is running:

```sh
rc-status
```

You should see the base services (networking, hostname, and so on). To see a
single service:

```sh
rc-service sshd status
```

For more, read **[SERVICES.md](SERVICES.md)**.

---

## 4. Get on the network

If you chose a wired connection in the installer, it should already be up.

Wi-Fi and wired networking are managed by **NetworkManager**, which ships with
`nmcli` and the text UI `nmtui`:

```sh
nmtui
```

Or from the command line:

```sh
nmcli device wifi list
nmcli device wifi connect "MyNetwork" password "my-password"
nmcli device status
```

NetworkManager and the firmware are already installed; you do not need to
emerge `wpa_supplicant` separately.

Then test:

```sh
ping -c3 gentoo.org
```

If it fails, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## 5. Keep the system up to date

Gentoo is a "rolling" distribution. To update everything:

```sh
su -
emerge --sync                 # download the latest package list
emerge --ask --update @world  # update installed packages
```

Read any news items it shows:

```sh
eselect news read
```

---

## 6. Install more software

Search for a package:

```sh
emerge --search firefox
```

Install it:

```sh
su -
emerge --ask firefox
```

You do **not** need to edit `make.conf` to install normal software. The
pre-made file already works on almost every device.

---

## 7. Where things live

| Path | What it is |
| --- | --- |
| `/etc/init.d/` | service scripts (start/stop programs) |
| `/etc/runlevels/` | which services start at boot |
| `/etc/conf.d/` | per-service settings (hostname, network, ...) |
| `/etc/portage/make.conf` | how packages are built (see the editing guide) |
| `/var/log/` | system logs |

---

## 8. Next steps

- Tune the build for your device: **[EDITING-MAKE-CONF.md](EDITING-MAKE-CONF.md)**
- Learn services: **[SERVICES.md](SERVICES.md)**
- Understand boot: **[BOOT.md](BOOT.md)**
