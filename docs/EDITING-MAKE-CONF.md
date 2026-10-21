# Editing `make.conf` for your device

`make.conf` is the main configuration file for building packages. genbox ships
a **pre-made** one that works on almost every device. You only edit it if you
want to tune performance or behavior for *your* computer.

The file lives at:

```
/etc/portage/make.conf
```

---

## The golden rule

**If you are unsure, do not edit it.** The defaults are safe and correct.

If you *do* edit it:

1. Make a backup first: `cp /etc/portage/make.conf /etc/portage/make.conf.bak`
2. Edit it with a text editor, for example:
   ```sh
   su -
   nano /etc/portage/make.conf
   ```
3. After saving, rebuild anything affected:
   ```sh
   emerge --ask --changed-use --update @world
   ```

---

## How the file is written

The pre-made `make.conf` is deliberately **full of comments** (lines starting
with `#`). Each setting looks like this:

```sh
MAKEOPTS="-j4"
```

- `MAKEOPTS` is the **name** of the setting.
- `-j4` is the **value**, always inside quotes.

To change a value, edit the text inside the quotes. Do not remove the quotes.

---

## Common edits people make

### "My computer has more/fewer CPU cores"

Change `MAKEOPTS` to match your CPU:

```sh
MAKEOPTS="-j8"      # 8 cores
MAKEOPTS="-j2"      # 2 cores, low memory
```

To see how many cores you have:

```sh
nproc
```

### "I have lots of RAM and want faster builds"

```sh
MAKEOPTS="-j12"
EMERGE_DEFAULT_OPTS="--ask --quiet-build=y --jobs=4 --load-average=12"
```

More jobs = more memory used. If the machine becomes unresponsive or a build
is "killed", lower these numbers.

### "I only build for this one machine, and want extra speed"

Change the CFLAGS line:

```sh
CFLAGS="-O2 -pipe -march=native"
```

> **Caution:** `-march=native` makes packages that only run on *this exact
> CPU model*. Do not use it if you copy binaries to another machine.

### "I want smaller, faster packages but slightly slower code"

```sh
CFLAGS="-Os -pipe"
```

`-Os` optimizes for size. Good for tiny devices and USB installs.

### "I am low on disk space"

Remove `buildpkg` from the `FEATURES` line so Portage does not keep old
binary packages:

```sh
FEATURES="sandbox userfetch parallel-install"
```

You can also clean up with:

```sh
su -
emerge --ask --depclean
eclean-dist
```

### "I want a different language for messages"

```sh
LINGUAS="de fr"
L10N="de fr"
```

### "I have a very quiet laptop and want builds to be gentle"

```sh
MAKEOPTS="-j2"
PORTAGE_NICENESS="15"
```

---

## USE flags (turning features on/off)

`USE` is a space-separated list of feature names. Names with a **minus sign**
are turned *off*:

```sh
USE="-openrc -systemd -udev mdev"
```

- `-openrc` means "do not include OpenRC".
- `mdev` means "use BusyBox mdev for devices".

> **Do not remove `-openrc`, `-systemd`, `-udev`, or `mdev`.** They are how
> genbox stays genbox.

To add your own feature, append it:

```sh
USE="-openrc -systemd -udev mdev bluetooth"
```

You can always inspect what a flag does:

```sh
equery uses <package>
```

(Install `app-portage/gentoolkit` first if `equery` is missing.)

---

## Per-package settings (advanced)

Sometimes you want a flag for *one* package only. Use
`/etc/portage/package.use`:

```sh
# /etc/portage/package.use
www-client/firefox system-av1
media-video/ffmpeg -vaapi
```

---

## Full reference

Every setting shipped in the pre-made file is described in normal language in
**[MAKE-CONF-REFERENCE.md](MAKE-CONF-REFERENCE.md)**.

---

## Undo everything

If you break something, restore the backup:

```sh
su -
cp /etc/portage/make.conf.bak /etc/portage/make.conf
```

The original pre-made file is also kept at `/etc/portage/make.conf.genbox` and
can be copied back at any time.
