#!/bin/sh
runit_start() { default_start_ssd; }
runit_stop() { default_stop_ssd; }
runit_status() { default_status_ssd; }
default_start_ssd() { start-stop-daemon --start --pidfile "${pidfile}" ${command_args} --exec "${command}" 2>/dev/null || return 0; }
default_stop_ssd() { start-stop-daemon --stop --pidfile "${pidfile}" 2>/dev/null || return 0; }
default_status_ssd() { service_started && einfo "status: started" || einfo "status: stopped"; }
