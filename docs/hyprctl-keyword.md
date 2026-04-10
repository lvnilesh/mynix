# hyprctl keyword — Runtime Config Overrides

`hyprctl keyword` changes any Hyprland config setting at runtime without editing files. Changes are **temporary** — they revert on Hyprland restart or config reload (`hyprctl reload`).

## Syntax

```bash
hyprctl keyword <section>:<key> <value>
```

## Cursor Examples

```bash
# Disable cursor auto-hide after inactivity (default in our config: 30s)
hyprctl keyword cursor:inactive_timeout 0

# Disable cursor hiding on key press (default in our config: true)
hyprctl keyword cursor:hide_on_key_press false

# Toggle hardware cursors
hyprctl keyword cursor:no_hardware_cursors false
```

## Troubleshooting: "Cursor disappeared"

The cursor section in `dotfiles/hyprland.conf` has:
- `hide_on_key_press = true` — cursor hides when any key is pressed
- `inactive_timeout = 30` — cursor hides after 30s with no mouse movement

If the cursor seems gone, **move the mouse** — it comes back. If that doesn't work:

```bash
# From SSH or a terminal you can still type in:
HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1001/hypr/ | head -1) \
  hyprctl keyword cursor:inactive_timeout 0
```

## Other Useful Overrides

```bash
# Change gaps on the fly
hyprctl keyword general:gaps_in 0
hyprctl keyword general:gaps_out 0

# Disable animations temporarily
hyprctl keyword animations:enabled false

# Change border size
hyprctl keyword general:border_size 2
```

## Notes

- Requires `HYPRLAND_INSTANCE_SIGNATURE` when running via SSH (not set outside the Hyprland session).
- To make changes permanent, edit `~/mynix/dotfiles/hyprland.conf` instead.
