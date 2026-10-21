#!/bin/sh
RC_SVCNAME="$1"
shift
depend() { :; }
need() { [ -n "$*" ] && echo "$RC_SVCNAME need $*" >&3; }
use() { [ -n "$*" ] && echo "$RC_SVCNAME use $*" >&3; }
want() { [ -n "$*" ] && echo "$RC_SVCNAME want $*" >&3; }
before() { [ -n "$*" ] && echo "$RC_SVCNAME before $*" >&3; }
after() { [ -n "$*" ] && echo "$RC_SVCNAME after $*" >&3; }
provide() { [ -n "$*" ] && echo "$RC_SVCNAME provide $*" >&3; }
config() { [ -n "$*" ] && echo "$RC_SVCNAME config $*" >&3; }
keyword() { [ -n "$*" ] && echo "$RC_SVCNAME keyword $*" >&3; }
. "$RC_SERVICE" 2>/dev/null
if command -v depend >/dev/null 2>&1; then
	depend
fi
