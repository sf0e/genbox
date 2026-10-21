# `make.conf` settings reference

This page explains **every setting** in the pre-made genbox `make.conf`, in
plain language. For *how* to edit, see
[EDITING-MAKE-CONF.md](EDITING-MAKE-CONF.md).

---

## `CFLAGS` and `CXXFLAGS`

**What it does:** tells the compiler how to optimize the code it builds.

- `CFLAGS` is for C programs.
- `CXXFLAGS` is for C++ programs (it copies `CFLAGS` here).

| Option | Meaning |
| --- | --- |
| `-O2` | Good, safe optimization. |
| `-O3` | More optimization, bigger and occasionally buggy code. |
| `-Os` | Optimize for small size. |
| `-pipe` | Uses pipes between build steps. Saves memory and disk. |
| `-march=native` | Tune for *this* CPU only (not portable). |

**genbox default:** `-O2 -pipe` - works everywhere, portable between machines.

---

## `MAKEOPTS`

**What it does:** how many things to compile at the same time.

`-jN` means "use N parallel jobs". More jobs finish sooner but need more RAM.
A rough rule: about **2 GB of RAM per job**.

**genbox default:** `-j4`.

---

## `ACCEPT_LICENSE`

**What it does:** which software licenses you automatically agree to.

- `*` accepts free/open-source licenses without asking.
- `-@EULA` refuses end-user-license agreements (they can restrict your rights).

**genbox default:** `* -@EULA` - convenient, and does not silently accept
restrictive licenses.

---

## `USE`

**What it does:** turns optional features of packages on or off, system-wide.

- A plain name (`mdev`) turns the feature ON.
- A name with a minus (`-systemd`) turns it OFF.

**genbox default:** `-openrc -systemd -udev mdev`

| Flag | Meaning here |
| --- | --- |
| `-openrc` | Do not install/use OpenRC. |
| `-systemd` | Do not install/use systemd. |
| `-udev` | Do not install/use udev. |
| `mdev` | Use BusyBox `mdev` to manage device files. |

> These four are the heart of genbox. Leave them alone.

---

## `CPU_FLAGS_X86`

**What it does:** lists CPU instructions the compiler may use.

A wrong value can crash programs with "illegal instruction". The default is
safe for all modern amd64 CPUs. For a small speed-up on your own machine:

```sh
emerge --ask app-portage/cpuid2cpuflags
cpuid2cpuflags
```

Then paste the result into `make.conf`.

**genbox default:** `mmx mmxext sse sse2`.

---

## `VIDEO_CARDS`

**What it does:** which graphics drivers to build. Only matters if you install
graphical software.

| Value | For |
| --- | --- |
| `amdgpu` | Modern AMD GPUs |
| `radeon` / `radeonsi` | Older and newer AMD GPUs |
| `intel` | Intel graphics |
| `nouveau` | NVIDIA (open-source driver) |
| `nvidia` | NVIDIA (proprietary driver) |
| `vesa` / `fbdev` | Fallback / generic |

**genbox default:** all the common ones, so any machine works.

---

## `INPUT_DEVICES`

**What it does:** input hardware support (keyboard, mouse, touchpad).

**genbox default:** `libinput` - the modern, universal choice for X.org and
Wayland.

---

## `GRUB_PLATFORMS`

**What it does:** which bootloader targets to build for GRUB.

- `pc` is the old BIOS boot method.
- `efi-64` is modern 64-bit UEFI.

**genbox default:** `pc efi-64` - one install works on any amd64 machine.

> Do not remove either value unless you are certain which firmware your
> machine uses.

---

## `LINGUAS` and `L10N`

**What it does:** which languages to include translations for.

- `LINGUAS` is the classic variable.
- `L10N` is the newer name used by many packages.

Use space-separated two-letter codes: `en de fr es`.

**genbox default:** `en`.

---

## `EMERGE_DEFAULT_OPTS`

**What it does:** options applied to every `emerge` command automatically.

| Option | Meaning |
| --- | --- |
| `--ask` | Always confirm before making changes. |
| `--quiet-build=y` | Print less output while compiling. |
| `--jobs=N` | Build up to N packages at the same time. |
| `--load-average=N` | Do not start new jobs if the machine is busy. |

**genbox default:**
`--ask --quiet-build=y --jobs=2 --load-average=8`.

---

## `FEATURES`

**What it does:** turns Portage behaviors on or off.

| Feature | Meaning |
| --- | --- |
| `sandbox` | Catch builds that try to write outside their area. |
| `userfetch` | Download source as your normal user, build as root. |
| `buildpkg` | Keep a binary copy of everything you build. |
| `parallel-install` | Install packages while others are still building. |

**genbox default:** `sandbox userfetch buildpkg parallel-install`.

Remove `buildpkg` if you are short on disk space.

---

## `GENTOO_MIRRORS`

**What it does:** where to download source code from.

An empty value means "use the mirrors that were configured during install".

**genbox default:** empty.

---

## `PORTAGE_NICENESS`

**What it does:** how much to "slow down" builds so the rest of the system
stays responsive. Higher = more polite.

**genbox default:** `10`.

---

## Related files (not in `make.conf`)

| File | Purpose |
| --- | --- |
| `/etc/portage/package.use` | USE flags for specific packages |
| `/etc/portage/package.accept_keywords` | allow testing/unstable versions |
| `/etc/portage/package.mask` | forbid certain versions |
| `/etc/portage/repos.conf/` | where package repositories come from |

---

## Portable defaults

The whole point of the pre-made file is that a **single file** works on:

- Desktops and laptops,
- Virtual machines (QEMU, VirtualBox, VMware),
- Both wired and wireless networks,
- Intel, AMD, and NVIDIA graphics,
- Low-memory and high-memory machines.

You should never *have* to edit it. It exists to be a friendly starting point.
