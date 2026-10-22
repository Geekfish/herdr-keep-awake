#!/usr/bin/env bash
set -eu
HERDR_KEEP_AWAKE_TEST=1 . "$(dirname "$0")/../scripts/keep-awake-watch.sh"

expect() {
	if echo "$2" | any_agent_working; then got=yes; else got=no; fi
	[ "$got" = "$1" ] || { echo "FAIL: expected $1 for $2"; exit 1; }
}

expect yes '{"result":{"agents":[{"agent_status":"idle"},{"agent_status":"working"}]}}'
expect yes '{"result":{"agents":[{"agent_status": "working"}]}}'
expect no '{"result":{"agents":[{"agent_status":"idle"},{"agent_status":"blocked"}]}}'
expect no '{"result":{"agents":[]}}'
echo ok
