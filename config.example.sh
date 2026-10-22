# shellcheck shell=bash
# herdr-keep-awake configuration. Copy it to the plugin config directory:
#
#   cp config.example.sh "$(herdr plugin config-dir herdr-keep-awake)/config.sh"
#
# Restart Herdr to apply changes. The watcher reads this file once.

# Seconds between checks of the agent status.
#HERDR_KEEP_AWAKE_INTERVAL="${HERDR_KEEP_AWAKE_INTERVAL:-10}"

# caffeinate flags. Add -s to also stay awake with the lid closed on AC power,
# or -d to keep the display on.
#HERDR_KEEP_AWAKE_FLAGS="${HERDR_KEEP_AWAKE_FLAGS:--i}"
