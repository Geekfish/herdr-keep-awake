# herdr-keep-awake

A [Herdr](https://herdr.dev) plugin that keeps your Mac awake while any agent in Herdr is working.

Herdr tracks the status of every agent kind (Claude Code, Codex, OpenCode and others). So the plugin works for all of them, without hooks for each agent. When no agent is working, the Mac can sleep as usual.

## Requirements

- Herdr 0.8.0 or newer
- macOS. The plugin uses `caffeinate`, which macOS includes.

## Install

```bash
herdr plugin install Geekfish/herdr-keep-awake
```

Restart Herdr to start the plugin.

## How it works

- A startup command checks `herdr agent list` every 10 seconds.
- If an agent has the status `working`, the plugin starts `caffeinate -i`. When no agent is working, the plugin stops it.
- `caffeinate` watches the plugin process with `-w`. If the plugin stops or crashes, `caffeinate` exits too, so the Mac cannot stay awake by mistake.

`-i` blocks idle sleep only. If you close the lid on battery power, the Mac still sleeps.

The plugin trusts the status that Herdr detects. If Herdr shows an agent as idle during a long tool call, the Mac can sleep.

To see the state in the Herdr sidebar, use [herdr-caffeinated](https://github.com/tgdn/herdr-caffeinated). The two plugins work together without configuration.

## Configuration

The settings are optional. Copy the example file and edit it:

```bash
cp config.example.sh "$(herdr plugin config-dir herdr-keep-awake)/config.sh"
```

| Setting | Default | Purpose |
| --- | --- | --- |
| `HERDR_KEEP_AWAKE_INTERVAL` | `10` | Seconds between checks |
| `HERDR_KEEP_AWAKE_FLAGS` | `-i` | `caffeinate` flags. Add `-s` to stay awake with the lid closed on AC power, or `-d` to keep the display on. |

Restart Herdr to apply changes.

## Troubleshooting

Make sure that the watcher runs:

```bash
pgrep -lf keep-awake-watch
```

While an agent works, this shows the `caffeinate` process that the plugin holds:

```bash
pgrep -lf "caffeinate -i -w"
```

## Test

```bash
bash tests/any-agent-working-test.sh
```

## Uninstall

```bash
herdr plugin uninstall herdr-keep-awake
```

## License

[MIT](LICENSE)
