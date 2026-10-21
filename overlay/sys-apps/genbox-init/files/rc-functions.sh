#!/bin/sh
# genbox rc-functions.sh

RC_GOT_FUNCTIONS="yes"

. "${GENBOX_LIB:-/usr/libexec/genbox}/sh/functions.sh"

rc_runlevel()
{
	[ -r /run/openrc/softlevel ] && cat /run/openrc/softlevel || echo "default"
}

rc_runlevel_get()
{
	rc_runlevel
}

rc_sys()
{
	echo "${RC_SYS:-}"
}

rc_is_user()
{
	[ -n "$RC_USER_SERVICES" ] && return 0
	return 1
}

rc_service_state()
{
	local svc="$1"
	if service_started "$svc"; then
		echo "started"
		return 0
	fi
	if service_stopped "$svc"; then
		echo "stopped"
		return 0
	fi
	echo "stopped"
	return 0
}

rc_service_mark()
{
	local svc="$1"
	local state="$2"
	RC_SVCNAME="$svc"
	case "$state" in
		RC_SERVICE_STARTED) mark_service_started ;;
		RC_SERVICE_STOPPED) mark_service_stopped ;;
		RC_SERVICE_STARTING) mark_service_starting ;;
		RC_SERVICE_STOPPING) mark_service_stopping ;;
		RC_SERVICE_INACTIVE) mark_service_inactive ;;
		RC_SERVICE_FAILED) mark_service_failed ;;
		*) return 1 ;;
	esac
}

RC_SERVICE_STARTED=started
RC_SERVICE_STOPPED=stopped
RC_SERVICE_STARTING=starting
RC_SERVICE_STOPPING=stopping
RC_SERVICE_INACTIVE=inactive
RC_SERVICE_HOTPLUGGED=hotplugged
RC_SERVICE_FAILED=failed
RC_SERVICE_CRASHED=crashed
