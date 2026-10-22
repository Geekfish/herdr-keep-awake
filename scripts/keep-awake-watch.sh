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
# -i blocks idle sleep only. Closing the lid on battery still sleeps the Mac.
HERDR_KEEP_AWAKE_FLAGS="${HERDR_KEEP_AWAKE_FLAGS:--i}"

# Reads `herdr agent list` JSON on stdin. Exit 0 if any agent is working.
# grep instead of jq, so the plugin needs no extra install.
any_agent_working() {
	grep -qE '"agent_status"[[:space:]]*:[[:space:]]*"working"'
}

# Sourced by the test: stop before the loop.
[ "${HERDR_KEEP_AWAKE_TEST:-}" = 1 ] && return 0

caffeinate_pid=""
sleep_pid=""

release() {
	[ -n "$caffeinate_pid" ] && kill "$caffeinate_pid" 2>/dev/null
	caffeinate_pid=""
}

trap 'release; [ -n "$sleep_pid" ] && kill "$sleep_pid" 2>/dev/null; exit 0' TERM INT

while :; do
	if "$HERDR_BIN" agent list 2>/dev/null | any_agent_working; then
		if [ -z "$caffeinate_pid" ] || ! kill -0 "$caffeinate_pid" 2>/dev/null; then
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
