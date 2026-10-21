#!/bin/sh
# genbox functions.sh - OpenRC-compatible
# Byte-exact reimplementation of OpenRC's libeinfo.c non-TTY output.

RC_GOT_FUNCTIONS="yes"
RC_LIBEXECDIR="${RC_LIBEXECDIR:-/usr/libexec/genbox}"
GENBOX_LIB="/usr/libexec/genbox"

# Print the "{ * |prefix} " marker and the message to $1 (stdout/stderr).
# Sets _EINFO_COL to the column count, matching libeinfo.c's _einfo return.
_einfo()
{
	local fp="$1"
	shift
	local last="$EINFO_LASTCMD"
	local nl=""
	if [ -n "$last" ] && [ "$last" != "ewarn" ] && [ "${last%n}" != "$last" ]; then
		nl="
"
	fi
	local ind=${EINFO_INDENT:-0}
	local sp=""
	local i=0
	while [ $i -lt $ind ]; do
		sp=" $sp"
		i=$(( i + 1 ))
	done
	local msg="$*"
	local out="${nl} * ${sp}${msg}"
	if [ "$fp" = "stderr" ]; then
		printf "%s" "$out" >&2
	else
		printf "%s" "$out"
	fi
	_EINFO_COL=$(( ${#msg} + ind + 3 ))
}

ebegin()
{
	[ -z "$*" ] && return 0
	[ -n "$EINFO_QUIET" ] && return 0
	local last="$EINFO_LASTCMD"
	local nl=""
	if [ -n "$last" ] && [ "$last" != "ewarn" ] && [ "${last%n}" != "$last" ]; then
		nl="
"
	fi
	local ind=${EINFO_INDENT:-0}
	local sp=""
	local i=0
	while [ $i -lt $ind ]; do
		sp=" $sp"
		i=$(( i + 1 ))
	done
	printf "%s * %s%s ..." "$nl" "$sp" "$*"
	EINFO_LASTCMD="ebegin"
	export EINFO_LASTCMD
	return 0
}

# _eend_marker <col> <fp> <marker-text>
_eend_marker()
{
	local col="$1"
	local fp="$2"
	local msg="$3"
	local cols=$(( 80 - ( ${#msg} + 5 ) ))
	local pad=0
	[ "$col" -gt 0 ] && pad=$(( cols - col ))
	if [ "$fp" = "stderr" ]; then
		local i=0
		while [ $i -lt $pad ]; do
			printf " " >&2
			i=$(( i + 1 ))
		done
		printf " [ %s ]\n" "$msg" >&2
	else
		local i=0
		while [ $i -lt $pad ]; do
			printf " "
			i=$(( i + 1 ))
		done
		printf " [ %s ]\n" "$msg"
	fi
}

# $1 = badecolor cmd name ("eend"/"ewend"), $2 = retval, rest = message
_do_eend()
{
	local cmd="$1"
	local retval="$2"
	shift 2
	local col=0
	if [ -n "$*" ] && [ "$retval" -ne 0 ]; then
		if [ "$cmd" = "ewend" ]; then
			_einfo stderr "$@"
		else
			_einfo stderr "$@"
		fi
		printf "\n" >&2
		col=$(( _EINFO_COL + 1 ))
		if [ "$retval" -eq 0 ]; then
			_eend_marker "$col" stdout "ok"
		else
			_eend_marker "$col" stderr "!!"
		fi
		return "$retval"
	fi
	if [ "$retval" -eq 0 ]; then
		if [ "$col" -gt 0 ]; then
			_eend_marker "$col" stdout "ok"
		else
			printf " [ ok ]\n"
		fi
	else
		printf " [ !! ]\n"
	fi
	return "$retval"
}

eend()
{
	local retval="$1"
	shift
	[ -n "$EINFO_QUIET" ] && return "$retval"
	_do_eend "eend" "$retval" "$@"
	EINFO_LASTCMD="eend"
	export EINFO_LASTCMD
	return "$retval"
}

ewend()
{
	local retval="$1"
	shift
	[ -n "$EINFO_QUIET" ] && return "$retval"
	_do_eend "ewend" "$retval" "$@"
	EINFO_LASTCMD="ewend"
	export EINFO_LASTCMD
	return "$retval"
}

einfo()
{
	[ -n "$EINFO_QUIET" ] && return 0
	_einfo stdout "$@"
	printf "\n"
	EINFO_LASTCMD="einfo"
	export EINFO_LASTCMD
}

einfon()
{
	[ -n "$EINFO_QUIET" ] && return 0
	_einfo stdout "$@"
	EINFO_LASTCMD="einfon"
	export EINFO_LASTCMD
}

ewarn()
{
	[ -n "$EINFO_QUIET" ] && return 0
	_einfo stderr "$@"
	printf "\n" >&2
	EINFO_LASTCMD="ewarn"
	export EINFO_LASTCMD
}

ewarnn()
{
	[ -n "$EINFO_QUIET" ] && return 0
	_einfo stderr "$@"
	EINFO_LASTCMD="ewarnn"
	export EINFO_LASTCMD
}

eerror()
{
	[ -n "$EERROR_QUIET" ] && return 0
	_einfo stderr "$@"
	printf "\n" >&2
	EINFO_LASTCMD="eerror"
	export EINFO_LASTCMD
}

eerrorn()
{
	[ -n "$EERROR_QUIET" ] && return 0
	_einfo stderr "$@"
	EINFO_LASTCMD="eerrorn"
	export EINFO_LASTCMD
}

eindent()
{
	: $(( EINFO_INDENT = ${EINFO_INDENT:-0} + 2 ))
	export EINFO_INDENT
}

eoutdent()
{
	: $(( EINFO_INDENT = ${EINFO_INDENT:-0} - 2 ))
	[ "${EINFO_INDENT:-0}" -lt 0 ] && EINFO_INDENT=0
	export EINFO_INDENT
	return 0
}

vebegin() { ebegin "$@"; }
veend() { eend "$@"; }
veinfo() { einfo "$@"; }
vewarn() { ewarn "$@"; }
vewend() { ewend "$@"; }
veindent() { eindent; }
veoutdent() { eoutdent; }

yesno()
{
	[ -z "$1" ] && return 1
	case "$1" in
		[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
		[Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
	esac
	local value=""
	eval value=\"\$$1\"
	case "$value" in
		[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
		[Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
		*) return 2;;
	esac
}

checkpath()
{
	local mode="" type="" owner="" truncate="" file="" perms="" uid="" gid="" recursive=""
	checkpath_writable=""
	while [ $# -gt 0 ]; do
		case "$1" in
			-d|--directory) type="dir"; shift ;;
			-D|--directory-truncate) type="dir"; truncate="1"; shift ;;
			-f|--file) type="file"; shift ;;
			-F|--file-truncate) type="file"; truncate="1"; shift ;;
			-p|--pipe) type="pipe"; shift ;;
			-m|--mode) perms="$2"; shift 2 ;;
			-o|--owner) owner="$2"; shift 2 ;;
			-s|--symlinks) recursive="1"; shift ;;
			-W|--writable) checkpath_writable=1; shift ;;
			-U|--user) shift ;;
			-C|--nocolor) shift ;;
			-h|--help) checkpath_help; return 0 ;;
			-V) echo "checkpath (genbox)"; return 0 ;;
			-v|-q) shift ;;
			*) file="$1"; shift ;;
		esac
	done
	if [ -n "$checkpath_writable" ] && [ -w "${file:-.}" ]; then
		return 0
	fi
	if [ "$type" = "dir" ]; then
		[ -d "$file" ] || mkdir -p "$file"
		[ -n "$perms" ] && chmod "$perms" "$file"
		if [ -n "$owner" ]; then
			uid="${owner%%:*}"
			gid="${owner#*:}"
			[ "$uid" = "$owner" ] && gid=""
			chown ${uid}${gid:+:$gid} "$file" 2>/dev/null
		fi
		return 0
	fi
	if [ "$type" = "file" ]; then
		[ -e "$file" ] || { : > "$file"; }
		[ -n "$perms" ] && chmod "$perms" "$file"
		if [ -n "$owner" ]; then
			uid="${owner%%:*}"
			gid="${owner#*:}"
			[ "$uid" = "$owner" ] && gid=""
			chown ${uid}${gid:+:$gid} "$file" 2>/dev/null
		fi
		return 0
	fi
	if [ "$type" = "pipe" ]; then
		[ -p "$file" ] || mkfifo "$file"
		[ -n "$perms" ] && chmod "$perms" "$file"
		if [ -n "$owner" ]; then
			uid="${owner%%:*}"
			gid="${owner#*:}"
			[ "$uid" = "$owner" ] && gid=""
			chown ${uid}${gid:+:$gid} "$file" 2>/dev/null
		fi
		return 0
	fi
	return 0
}

checkpath_help()
{
	cat <<'EOF'
Usage: checkpath [options] <path>
  -d, --directory   check for directory, create if necessary
  -D, --directory-truncate   check for directory, truncate if necessary
  -f, --file        check for file, create if necessary
  -F, --file-truncate   check for file, truncate if necessary
  -p, --pipe        check for pipe, create if necessary
  -m, --mode        mode to check/set (octal)
  -o, --owner       owner to check/set (user:group)
  -s, --symlinks    check all symlinks
  -W, --writable    check if path is writable
  -h, --help        display this help output and exit
  -C, --nocolor     disable color output
  -V                print version
  -v, --verbose     increase verbosity of the output
  -q, --quiet       decrease verbosity of the output
  -U, --user        runs in user mode
EOF
}

start-stop-daemon()
{
	/sbin/start-stop-daemon "$@"
}

is_new_net()
{
	return 1
}

rc_svcdir()
{
	echo "${RC_SVCDIR:-/var/lib/init.d}"
}

_service_set_value()
{
	local service="$1"
	local name="$2"
	local value="$3"
	[ -z "$service" -o -z "$name" ] && return 1
	[ -d "${RC_SVCDIR}/$service" ] || mkdir -p "${RC_SVCDIR}/$service"
	if [ -n "$value" ]; then
		printf "%s" "$value" > "${RC_SVCDIR}/$service/$name"
	else
		: > "${RC_SVCDIR}/$service/$name"
	fi
	return 0
}

_service_get_value()
{
	local service="$1"
	local name="$2"
	[ -z "$service" -o -z "$name" ] && return 1
	[ -r "${RC_SVCDIR}/$service/$name" ] || return 1
	cat "${RC_SVCDIR}/$service/$name"
	return 0
}

service_set_value()
{
	local name="$1"
	shift
	_service_set_value "${RC_SVCNAME:-$SVCNAME}" "$name" "$*"
}

service_get_value()
{
	local name="$1"
	_service_get_value "${RC_SVCNAME:-$SVCNAME}" "$name"
}

mark_service_started()
{
	mkdir -p "${RC_SVCDIR}/started" 2>/dev/null
	rm -f "${RC_SVCDIR}/stopped/$RC_SVCNAME" "${RC_SVCDIR}/starting/$RC_SVCNAME" "${RC_SVCDIR}/stopping/$RC_SVCNAME" "${RC_SVCDIR}/inactive/$RC_SVCNAME" 2>/dev/null
	_service_set_value "$RC_SVCNAME" "started" "1"
	ln -sf "$RC_SVCNAME" "${RC_SVCDIR}/started/$RC_SVCNAME" 2>/dev/null
	mkdir -p "${RC_SVCDIR}/softlevel/${RC_SOFTLEVEL:-default}" 2>/dev/null
	ln -sf "$RC_SVCNAME" "${RC_SVCDIR}/softlevel/${RC_SOFTLEVEL:-default}/$RC_SVCNAME" 2>/dev/null
}

mark_service_stopped()
{
	mkdir -p "${RC_SVCDIR}/stopped" 2>/dev/null
	rm -f "${RC_SVCDIR}/$RC_SVCNAME/started" "${RC_SVCDIR}/$RC_SVCNAME/starting" "${RC_SVCDIR}/$RC_SVCNAME/inactive" "${RC_SVCDIR}/$RC_SVCNAME/stopping" 2>/dev/null
	rm -f "${RC_SVCDIR}/started/$RC_SVCNAME" "${RC_SVCDIR}/starting/$RC_SVCNAME" "${RC_SVCDIR}/stopping/$RC_SVCNAME" "${RC_SVCDIR}/inactive/$RC_SVCNAME" 2>/dev/null
	ln -sf "$RC_SVCNAME" "${RC_SVCDIR}/stopped/$RC_SVCNAME" 2>/dev/null
}

mark_service_starting()
{
	mkdir -p "${RC_SVCDIR}/starting" 2>/dev/null
	_service_set_value "$RC_SVCNAME" "starting" "1"
	ln -sf "$RC_SVCNAME" "${RC_SVCDIR}/starting/$RC_SVCNAME" 2>/dev/null
}

mark_service_stopping()
{
	mkdir -p "${RC_SVCDIR}/stopping" 2>/dev/null
	_service_set_value "$RC_SVCNAME" "stopping" "1"
	ln -sf "$RC_SVCNAME" "${RC_SVCDIR}/stopping/$RC_SVCNAME" 2>/dev/null
}

mark_service_inactive()
{
	mkdir -p "${RC_SVCDIR}/inactive" 2>/dev/null
	rm -f "${RC_SVCDIR}/started/$RC_SVCNAME" "${RC_SVCDIR}/stopped/$RC_SVCNAME" 2>/dev/null
	_service_set_value "$RC_SVCNAME" "inactive" "1"
	ln -sf "$RC_SVCNAME" "${RC_SVCDIR}/inactive/$RC_SVCNAME" 2>/dev/null
}

mark_service_failed()
{
	_service_set_value "$RC_SVCNAME" "failed" "$1"
}

mark_service_hotplugged()
{
	_service_set_value "$RC_SVCNAME" "hotplugged" "1"
}

service_started()
{
	[ -L "${RC_SVCDIR}/started/$RC_SVCNAME" ] && return 0
	return 1
}

service_stopped()
{
	[ -L "${RC_SVCDIR}/stopped/$RC_SVCNAME" ] && return 0
	return 1
}

service_starting()
{
	[ -L "${RC_SVCDIR}/starting/$RC_SVCNAME" ] && return 0
	return 1
}

service_stopping()
{
	[ -L "${RC_SVCDIR}/stopping/$RC_SVCNAME" ] && return 0
	return 1
}

service_inactive()
{
	[ -L "${RC_SVCDIR}/inactive/$RC_SVCNAME" ] && return 0
	return 1
}

service_failed()
{
	[ -r "${RC_SVCDIR}/$RC_SVCNAME/failed" ] && return 0
	return 1
}

service_crashed()
{
	[ -r "${RC_SVCDIR}/$RC_SVCNAME/crashed" ] && return 0
	return 1
}

service_hotplugged()
{
	[ -r "${RC_SVCDIR}/$RC_SVCNAME/hotplugged" ] && return 0
	return 1
}

rc_get_pid()
{
	[ -r "${RC_SVCDIR}/$RC_SVCNAME/exclusive" ] && cat "${RC_SVCDIR}/$RC_SVCNAME/exclusive"
}

is_older_than()
{
	[ $# -lt 2 ] && return 1
	local ref="$1"
	shift
	[ ! -e "$ref" ] && return 0
	local ref_time
	ref_time=$(stat -c %Y "$ref" 2>/dev/null || stat -f %m "$ref" 2>/dev/null)
	local f
	for f in "$@"; do
		[ -e "$f" ] || continue
		local f_time
		f_time=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null)
		[ -n "$f_time" ] && [ -n "$ref_time" ] && [ "$f_time" -le "$ref_time" ] && return 0
	done
	return 1
}

get_bootconfig()
{
	return 0
}

save_options()
{
	local svc="$1"
	shift
	mkdir -p "${RC_SVCDIR}/options/$svc"
	local o
	for o in "$@"; do
		: > "${RC_SVCDIR}/options/$svc/$o"
	done
}

get_options()
{
	local svc="$1"
	shift
	local o
	for o in "$@"; do
		[ -e "${RC_SVCDIR}/options/$svc/$o" ] && return 0
	done
	return 1
}

rc_cgroup_cleanup()
{
	return 0
}

esyslog() { return 0; }
ewaitfile() { return 0; }
eval_ecolors() { echo ""; }

# mountinfo [-q] [-o] [-f REGEX] [--skip-point-regex RE] [--netdev]
#           [--nonetdev] [path]
# Report mount information from /proc/mounts. With no path, list all matching
# mount points. With -o, print mount options instead.
mountinfo()
{
	local quiet=0 opt=0 fre="" skipre="" netdev=0 nonetdev=0 path=""
	local netlist="${net_fs_list:-nfs nfs4 cifs smbfs} ${extra_net_fs_list:-}"

	while [ $# -gt 0 ]; do
		case "$1" in
			-q|--quiet) quiet=1; shift ;;
			-o|--options) opt=1; shift ;;
			-f|--fstype|--fstype-regex) fre="$2"; shift 2 ;;
			--skip-point-regex) skipre="$2"; shift 2 ;;
			--netdev) netdev=1; shift ;;
			--nonetdev) nonetdev=1; shift ;;
			--) shift ;;
			-*) shift ;;
			*) path="$1"; shift ;;
		esac
	done

	awk -v quiet="$quiet" -v opt="$opt" -v fre="$fre" -v skipre="$skipre" \
	    -v netdev="$netdev" -v nonetdev="$nonetdev" -v path="$path" \
	    -v netlist="$netlist" '
		BEGIN { n = split(netlist, net, " "); found = 0 }
		NF < 2 { next }
		{
			mp = $2; fs = $3; opts = $4
			if (path != "" && mp != path) next
			if (fre != "" && fs !~ fre) next
			if (skipre != "" && mp ~ skipre) next
			isnet = (opts ~ /(^|,)_netdev(,|$)/)
			for (i = 1; i <= n; i++) if (fs == net[i]) isnet = 1
			if (netdev && !isnet) next
			if (nonetdev && isnet) next
			found = 1
			if (quiet) next
			if (opt) print opts
			else print mp
		}
		END { exit(found ? 0 : 1) }' /proc/mounts
}

# get_bootparam <name>
# Return success if the kernel command line contains <name> or <name>=...
get_bootparam()
{
	local p
	[ -n "$1" ] || return 1
	for p in $(cat /proc/cmdline 2>/dev/null); do
		case "$p" in
			"$1"|"$1"=*) return 0 ;;
		esac
	done
	return 1
}

# fstabinfo [-q] [-o] [-t types] [--passno N] [--remount path] [mountpoint]
# Small replacement for OpenRC's fstabinfo helper.
fstabinfo()
{
	[ -r /etc/fstab ] || return 1
	local quiet=0 show_opts=0 types="" passno="" remount="" mnt=""

	while [ $# -gt 0 ]; do
		case "$1" in
			-q|--quiet) quiet=1; shift ;;
			-o|--options) show_opts=1; shift ;;
			-t|--type) types="$2"; shift 2 ;;
			--passno) passno="${2#=}"; shift 2 ;;
			--remount) remount="$2"; shift 2 ;;
			--) shift; break ;;
			-*) shift ;;
			*) mnt="$1"; shift ;;
		esac
	done

	if [ -n "$remount" ]; then
		mount -o remount "$remount"
		return $?
	fi

	local AWK='
	function intype(t, list,   n, a, i) {
		n = split(list, a, ",")
		for (i = 1; i <= n; i++) if (a[i] == t) return 1
		return 0
	}
	BEGIN { found = 0 }
	/^[ \t]*#/ { next }
	NF < 3 { next }
	{
		mp = $2; type = $3; opts = $4; pass = $6
		if (want_types != "" && !intype(type, want_types)) next
		if (want_pass != "" && pass != want_pass) next
		if (want_mnt != "" && mp != want_mnt && $1 != want_mnt) next
		found = 1
		if (want_pass != "") { print mp; next }
		if (want_opts) { print opts; next }
		print mp
	}
	END { exit(found ? 0 : 1) }
	'

	if [ -n "$passno" ]; then
		awk -v want_pass="$passno" "$AWK" /etc/fstab
	elif [ -n "$types" ]; then
		awk -v want_types="$types" -v want_opts="$show_opts" "$AWK" /etc/fstab
	elif [ -n "$mnt" ]; then
		if [ "$quiet" = 1 ]; then
			awk -v want_mnt="$mnt" "$AWK" /etc/fstab >/dev/null
		else
			awk -v want_mnt="$mnt" -v want_opts="$show_opts" "$AWK" /etc/fstab
		fi
	else
		awk -v want_opts="$show_opts" "$AWK" /etc/fstab
	fi
}

# kill_all <signal> [options] - send a signal to every process (not PID 1).
kill_all()
{
	local sig="${1:-15}"
	shift 2>/dev/null || true
	killall5 -"$sig" "$@" 2>/dev/null
	return $?
}

# shell_var <string>
# Turn a string into a valid shell variable suffix (used by the modules
# service for kernel-version-specific module lists).
shell_var()
{
	printf '%s' "$1" | sed 's/[^A-Za-z0-9_]/_/g'
}
