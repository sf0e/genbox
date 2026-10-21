# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="genbox init system"
HOMEPAGE="https://github.com/sf0e/genbox"
LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RDEPEND="sys-apps/busybox"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {
	dodir /sbin /bin /usr/bin /etc/init.d /etc/runlevels /etc/conf.d /etc/rc.conf.d /usr/libexec/genbox/sh /usr/libexec/genbox/bin /usr/libexec/genbox/console /var/lib/genbox /run/genbox

	# Shell libraries
	exeinto /usr/libexec/genbox/sh
	doexe "${FILESDIR}"/functions.sh
	doexe "${FILESDIR}"/rc-functions.sh
	doexe "${FILESDIR}"/openrc-run.sh
	doexe "${FILESDIR}"/gendepends.sh
	doexe "${FILESDIR}"/start-stop-daemon.sh
	doexe "${FILESDIR}"/supervise-daemon.sh
	doexe "${FILESDIR}"/runit.sh
	doexe "${FILESDIR}"/s6.sh
	doexe "${FILESDIR}"/rc-cgroup.sh
	doexe "${FILESDIR}"/sh/binfmt.sh
	doexe "${FILESDIR}"/sh/rc-mount.sh

	# Helper binaries (shell wrappers)
	exeinto /usr/libexec/genbox/bin
	doexe "${FILESDIR}"/bin/ebegin
	doexe "${FILESDIR}"/bin/eend
	doexe "${FILESDIR}"/bin/ewend
	doexe "${FILESDIR}"/bin/einfo
	doexe "${FILESDIR}"/bin/einfon
	doexe "${FILESDIR}"/bin/ewarn
	doexe "${FILESDIR}"/bin/ewarnn
	doexe "${FILESDIR}"/bin/eerror
	doexe "${FILESDIR}"/bin/eerrorn
	doexe "${FILESDIR}"/bin/eindent
	doexe "${FILESDIR}"/bin/eoutdent
	doexe "${FILESDIR}"/bin/esyslog
	doexe "${FILESDIR}"/bin/ewaitfile
	doexe "${FILESDIR}"/bin/eval_ecolors
	doexe "${FILESDIR}"/bin/checkpath
	doexe "${FILESDIR}"/bin/vebegin
	doexe "${FILESDIR}"/bin/veend
	doexe "${FILESDIR}"/bin/veinfo
	doexe "${FILESDIR}"/bin/vewarn
	doexe "${FILESDIR}"/bin/vewend
	doexe "${FILESDIR}"/bin/veindent
	doexe "${FILESDIR}"/bin/veoutdent

	# Service manager tools
	exeinto /sbin
	doexe "${FILESDIR}"/openrc-run
	doexe "${FILESDIR}"/rc-update
	doexe "${FILESDIR}"/rc-service
	doexe "${FILESDIR}"/rc-status
	doexe "${FILESDIR}"/rc
	doexe "${FILESDIR}"/start-stop-daemon
	dosym rc-service /sbin/service

	# initramfs builder and serial console helper
	exeinto /usr/sbin
	doexe "${FILESDIR}"/genbox-mkinitramfs
	doexe "${FILESDIR}"/genbox-serial-getty

	# init
	exeinto /sbin
	doexe "${FILESDIR}"/openrc
	doexe "${FILESDIR}"/openrc-init
	doexe "${FILESDIR}"/openrc-shutdown
	dosym busybox /sbin/init

	# inittab
	insinto /etc
	doins "${FILESDIR}"/inittab

	# rc.conf
	insinto /etc
	doins "${FILESDIR}"/rc.conf

	# base init.d scripts (must be executable)
	exeinto /etc/init.d
	doexe "${FILESDIR}"/init.d/*

	# conf.d
	insinto /etc/conf.d
	doins "${FILESDIR}"/conf.d/*

	# runlevel symlinks will be created in postinst
	keepdir /etc/runlevels/sysinit /etc/runlevels/boot /etc/runlevels/default /etc/runlevels/shutdown /etc/runlevels/nonetwork
}

pkg_postinst() {
	# BusyBox init must be PID 1.
	ln -sfn busybox "${ROOT}/sbin/init" 2>/dev/null || true

	# Remove dangling runlevel links left behind by unmerged packages
	# (for example udev/udev-trigger after switching to mdev).
	local l s
	for l in "${ROOT}"/etc/runlevels/*; do
		[ -d "$l" ] || continue
		for s in "$l"/*; do
			[ -L "$s" ] || continue
			[ -e "$s" ] || rm -f "$s"
		done
	done

	# Create runlevel symlinks
	local rl
	for rl in sysinit boot default shutdown nonetwork; do
		[ -d "${ROOT}/etc/runlevels/${rl}" ] || mkdir -p "${ROOT}/etc/runlevels/${rl}"
	done

	# sysinit
	local s
	for s in devfs dmesg sysfs mdev cgroups procfs; do
		[ -e "${ROOT}/etc/init.d/${s}" ] && ln -sf "/etc/init.d/${s}" "${ROOT}/etc/runlevels/sysinit/${s}" 2>/dev/null
	done

	# boot
	for s in binfmt bootmisc fsck hostname hwclock keymaps localmount loopback modules root swap sysctl termencoding save-keymaps save-termencoding seedrng; do
		[ -e "${ROOT}/etc/init.d/${s}" ] && ln -sf "/etc/init.d/${s}" "${ROOT}/etc/runlevels/boot/${s}" 2>/dev/null
	done

	# default
	for s in local netmount; do
		[ -e "${ROOT}/etc/init.d/${s}" ] && ln -sf "/etc/init.d/${s}" "${ROOT}/etc/runlevels/default/${s}" 2>/dev/null
	done

	# shutdown
	for s in killprocs mount-ro savecache; do
		[ -e "${ROOT}/etc/init.d/${s}" ] && ln -sf "/etc/init.d/${s}" "${ROOT}/etc/runlevels/shutdown/${s}" 2>/dev/null
	done

	# nonetwork
	[ -e "${ROOT}/etc/init.d/local" ] && ln -sf "/etc/init.d/local" "${ROOT}/etc/runlevels/nonetwork/local" 2>/dev/null
}
