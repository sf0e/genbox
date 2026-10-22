#!/bin/sh
# Minimal supervise-daemon support. genbox does not run a long-lived
# supervisor process; services started this way are ordinary background
# daemons with a pidfile.

supervise_start()
{
	if [ -z "$command" ]; then
		eerror "$RC_SVCNAME: command not defined"
		return 1
	fi
	local spidfile="${pidfile:-/run/${RC_SVCNAME}.pid}"
	local args="${command_args_foreground:-$command_args}"
	ebegin "Starting ${name:-$RC_SVCNAME}"
	/sbin/start-stop-daemon --start --background --make-pidfile \
		--pidfile "$spidfile" \
		${start_stop_daemon_args} \
		${command_user:+--user} "$command_user" \
		${directory:+--chdir} "$directory" \
		--exec "$command" -- $args
	eend $? "Failed to start ${name:-$RC_SVCNAME}"
}

supervise_stop()
{
	local spidfile="${pidfile:-/run/${RC_SVCNAME}.pid}"
	ebegin "Stopping ${name:-$RC_SVCNAME}"
	/sbin/start-stop-daemon --stop --pidfile "$spidfile" ${stopsig:+--signal} "$stopsig"
	eend $? "Failed to stop ${name:-$RC_SVCNAME}"
}

supervise_status()
{
	local spidfile="${pidfile:-/run/${RC_SVCNAME}.pid}"
	if /sbin/start-stop-daemon --test --stop --pidfile "$spidfile" 2>/dev/null; then
		einfo "status: started"
		return 0
	fi
	einfo "status: stopped"
	return 3
}
