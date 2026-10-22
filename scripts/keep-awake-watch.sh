#!/usr/bin/env bash
# Startup command: hold a caffeinate while any Herdr agent is working.
#
# Herdr tracks the status of every agent kind, so this works for all of them
# without agent-specific hooks.

set -u

HERDR_BIN="${HERDR_BIN_PATH:-herdr}"

if [ -n "${HERDR_PLUGIN_CONFIG_DIR:-}" ] && [ -r "$HERDR_PLUGIN_CONFIG_DIR/config.sh" ]; then
	# shellcheck source=/dev/null
	. "$HERDR_PLUGIN_CONFIG_DIR/config.sh"
fi
HERDR_KEEP_AWAKE_INTERVAL="${HERDR_KEEP_AWAKE_INTERVAL:-10}"
# A bad value would make sleep return at once and spin the loop.
case "$HERDR_KEEP_AWAKE_INTERVAL" in
'' | *[!0-9]*) HERDR_KEEP_AWAKE_INTERVAL=10 ;;
esac
if [ "$HERDR_KEEP_AWAKE_INTERVAL" -lt 1 ]; then
	HERDR_KEEP_AWAKE_INTERVAL=1
elif [ "$HERDR_KEEP_AWAKE_INTERVAL" -gt 3600 ]; then
	HERDR_KEEP_AWAKE_INTERVAL=3600
fi
# -i blocks idle sleep only. Closing the lid on battery still sleeps the Mac.
HERDR_KEEP_AWAKE_FLAGS="${HERDR_KEEP_AWAKE_FLAGS:--i}"

# Reads `herdr agent list` JSON on stdin. Exit 0 if any agent is working.
# grep instead of jq, so the plugin needs no extra install.
any_agent_working() {
	grep -qE '"agent_status"[[:space:]]*:[[:space:]]*"working"'
}

# Sourced by the test: stop before the loop.
if [ "${HERDR_KEEP_AWAKE_TEST:-}" = 1 ]; then
	return 0 2>/dev/null || exit 0
fi

caffeinate_pid=""
sleep_pid=""

# Checks the process name too: if caffeinate exited by itself, its PID can
# belong to another process by now.
holding() {
	[ -n "$caffeinate_pid" ] &&
		[ "$(ps -p "$caffeinate_pid" -o comm= 2>/dev/null)" = caffeinate ]
}

release() {
	holding && kill "$caffeinate_pid" 2>/dev/null
	caffeinate_pid=""
}

# A hung herdr CLI must not block the loop while caffeinate is held.
# perl ships with macOS, coreutils timeout does not. perl relays the output
# itself, so a child of herdr that keeps the pipe open cannot block it either.
agent_list() {
	perl -e '
		my $s = shift;
		my $pid = open(my $out, "-|", @ARGV) or exit 1;
		$SIG{ALRM} = sub { kill "TERM", $pid; exit 1 };
		alarm $s;
		print while <$out>;
	' 5 "$HERDR_BIN" agent list 2>/dev/null
}

trap 'release; [ -n "$sleep_pid" ] && kill "$sleep_pid" 2>/dev/null; exit 0' TERM INT

while :; do
	if agent_list | any_agent_working; then
		if ! holding; then
			# -w ties caffeinate to this script, so a killed watcher cannot
			# leave the Mac awake.
			# shellcheck disable=SC2086
			caffeinate $HERDR_KEEP_AWAKE_FLAGS -w "$$" &
			caffeinate_pid=$!
		fi
	else
		release
	fi

	# Background sleep: bash runs traps only after a foreground child exits.
	sleep "$HERDR_KEEP_AWAKE_INTERVAL" &
	sleep_pid=$!
	wait "$sleep_pid" 2>/dev/null || true
	sleep_pid=""
done
