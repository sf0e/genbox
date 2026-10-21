#!/bin/sh
GENBOX_LIB="/usr/libexec/genbox"
[ -z "$RC_LIBEXECDIR" ] && RC_LIBEXECDIR="/usr/libexec/genbox"
export RC_LIBEXECDIR GENBOX_LIB

sourcex()
{
	if [ "$1" = "-e" ]; then
		shift
		[ -e "$1" ] || return 1
	fi
	[ -e "$1" ] || { eerror "$RC_SVCNAME: cannot load $1" 2>/dev/null; exit 1; }
	. "$1" || { eerror "$RC_SVCNAME: error loading $1" 2>/dev/null; exit 1; }
}

[ -r "${GENBOX_LIB}/sh/functions.sh" ] && . "${GENBOX_LIB}/sh/functions.sh"
[ -r "${GENBOX_LIB}/sh/rc-functions.sh" ] && . "${GENBOX_LIB}/sh/rc-functions.sh"

if [ $# != 2 ]; then
	[ -n "$RC_SVCNAME" ] && eerror "$RC_SVCNAME: invalid arguments"
	exit 1
fi

RC_SERVICE="$1"; export RC_SERVICE
shift
SVCNAME="$RC_SVCNAME"; export SVCNAME

[ -z "$RC_UNAME" ] && RC_UNAME="$(uname -s)"
net_fs_list="${net_fs_list:-afs ceph cifs coda davfs fuse fuse.glusterfs fuse.sshfs gfs glusterfs lustre ncpfs nfs nfs4 ocfs2 shfs smbfs}"
extra_net_fs_list="${extra_net_fs_list:-}"
export RC_UNAME net_fs_list extra_net_fs_list

config() { [ -n "$*" ] && echo "config $*"; }
need() { [ -n "$*" ] && echo "need $*"; }
use() { [ -n "$*" ] && echo "use $*"; }
want() { [ -n "$*" ] && echo "want $*"; }
before() { [ -n "$*" ] && echo "before $*"; }
after() { [ -n "$*" ] && echo "after $*"; }
provide() { [ -n "$*" ] && echo "provide $*"; }
keyword() { [ -n "$*" ] && echo "keyword $*"; }

describe()
{
	if [ -n "$description" ]; then
		einfo "$description"
	else
		ewarn "No description for $RC_SVCNAME"
	fi
	local svc= desc=
	for svc in ${extra_commands:-$opts} $extra_started_commands $extra_stopped_commands; do
		eval desc=\$description_$svc
		if [ -n "$desc" ]; then
			einfo "$HILITE$svc$NORMAL: $desc"
		else
			ewarn "$HILITE$svc$NORMAL: no description"
		fi
	done
}

_status()
{
	if service_stopping 2>/dev/null; then
		ewarn "status: stopping"; return 4
	elif service_starting 2>/dev/null; then
		ewarn "status: starting"; return 8
	elif service_inactive 2>/dev/null; then
		ewarn "status: inactive"; return 16
	elif service_crashed 2>/dev/null; then
		eerror "status: crashed"; return 32
	elif service_started 2>/dev/null; then
		einfo "status: started"; return 0
	else
		einfo "status: stopped"; return 3
	fi
}

default_start()
{
	local func=ssd_start
	case "$supervisor" in
		runit) func=runit_start ;;
		s6) func=s6_start ;;
		supervise-daemon) func=supervise_start ;;
		?*) ewarn "Invalid supervisor, \"$supervisor\", using start-stop-daemon" ;;
	esac
	$func
}

default_stop()
{
	local func=ssd_stop
	case "$supervisor" in
		runit) func=runit_stop ;;
		s6) func=s6_stop ;;
		supervise-daemon) func=supervise_stop ;;
		?*) ewarn "Invalid supervisor, \"$supervisor\", using start-stop-daemon" ;;
	esac
	$func
}

default_status()
{
	local func=ssd_status
	case "$supervisor" in
		runit) func=runit_status ;;
		s6) func=s6_status ;;
		supervise-daemon) func=supervise_status ;;
		?*) ewarn "Invalid supervisor, \"$supervisor\", using start-stop-daemon" ;;
	esac
	$func
}

default_reload()
{
	case "$supervisor" in
		s6) s6_reload ;;
		*) eerror "$RC_SVCNAME: undefined function 'reload'"; exit 1 ;;
	esac
}

start() { default_start; }
stop() { default_stop; }
status() { default_status; }
reload() { default_reload; }

[ -z "$RC_SVCDIR" ] && RC_SVCDIR="/var/lib/init.d"
[ -z "$RC_RUNLEVEL" ] && RC_RUNLEVEL=$(rc_runlevel 2>/dev/null || echo default)
export RC_SVCDIR RC_RUNLEVEL

mkdir -p "$RC_SVCDIR" /run/openrc /etc/init.d /etc/conf.d

sourcex -e "/etc/rc.conf" 2>/dev/null
if [ -d "/etc/rc.conf.d" ]; then
	for _f in /etc/rc.conf.d/*.conf; do
		[ -e "$_f" ] && sourcex -e "$_f"
	done
fi

_conf_d=${RC_SERVICE%/*}/../conf.d
_c=${RC_SVCNAME%%.*}
if [ -n "$_c" ] && [ "$_c" != "$RC_SVCNAME" ]; then
	sourcex -e "$_conf_d/$_c.$RC_RUNLEVEL" 2>/dev/null || sourcex -e "$_conf_d/$_c" 2>/dev/null
fi
sourcex -e "$_conf_d/$RC_SVCNAME.$RC_RUNLEVEL" 2>/dev/null || sourcex -e "$_conf_d/$RC_SVCNAME" 2>/dev/null
[ -n "$RC_USER_SERVICES" ] && sourcex -e "${XDG_CONFIG_HOME:-$HOME/.config}/rc/conf.d/$RC_SVCNAME" 2>/dev/null

[ -r "${GENBOX_LIB}/sh/runit.sh" ] && . "${GENBOX_LIB}/sh/runit.sh"
[ -r "${GENBOX_LIB}/sh/s6.sh" ] && . "${GENBOX_LIB}/sh/s6.sh"
[ -r "${GENBOX_LIB}/sh/start-stop-daemon.sh" ] && . "${GENBOX_LIB}/sh/start-stop-daemon.sh"
[ -r "${GENBOX_LIB}/sh/supervise-daemon.sh" ] && . "${GENBOX_LIB}/sh/supervise-daemon.sh"
[ -r "${GENBOX_LIB}/sh/rc-cgroup.sh" ] && . "${GENBOX_LIB}/sh/rc-cgroup.sh"

sourcex "$RC_SERVICE"

if yesno "${rc_verbose:-$RC_VERBOSE}"; then
	EINFO_VERBOSE=yes
	export EINFO_VERBOSE
fi

_setup_cgroup() {
	[ -w /sys/fs/cgroup ] || return 0
	return 0
}

for _d in $required_dirs; do
	[ -n "$_d" ] && [ ! -d "$_d" ] && { eerror "$RC_SVCNAME: \`$_d' is not a directory" 2>/dev/null; exit 1; }
done

for _f in $required_files; do
	[ -n "$_f" ] && [ ! -r "$_f" ] && { eerror "$RC_SVCNAME: \`$_f' is not readable" 2>/dev/null; exit 1; }
done

if [ "$1" = "depend" ]; then
	cd "${RC_SERVICE%/*}" 2>/dev/null || cd /
	command -v depend >/dev/null 2>&1 && depend
	cd /
	exit 0
fi

for _cmd in describe start stop status ${extra_commands:-$opts} $extra_started_commands $extra_stopped_commands; do
	[ "$_cmd" = "$1" ] || continue
	if [ "$(command -v "$1")" != "$1" ]; then
		case $_cmd in
			start|stop) exit 0 ;;
			*) eerror "$RC_SVCNAME: function '$1' defined but does not exist" 2>/dev/null; exit 1 ;;
		esac
		break
	fi
done

if yesno $IN_BACKGROUND 2>/dev/null; then
	for _cmd in $in_background_fake; do
		[ "$_cmd" = "$1" ] && exit 0
	done
fi

for _cmd in $extra_started_commands; do
	[ "$_cmd" = "$1" ] || continue
	if ! service_started 2>/dev/null; then
		eerror "$RC_SVCNAME: cannot '$1' as it has not been started" 2>/dev/null; exit 1
	fi
done

for _cmd in $extra_stopped_commands; do
	[ "$_cmd" = "$1" ] || continue
	if ! service_stopped 2>/dev/null; then
		eerror "$RC_SVCNAME: cannot '$1' as it has not been stopped" 2>/dev/null; exit 1
	fi
done

case $1 in
	start|stop|status) : ;;
esac

[ "$(command -v "$1_pre")" = "$1_pre" ] && { "$1"_pre || exit $?; }
"$1" || exit $?
[ "$(command -v "$1_post")" = "$1_post" ] && { "$1"_post || exit $?; }

case $1 in
	start) mark_service_started ;;
	stop) mark_service_stopped ;;
esac

exit 0
