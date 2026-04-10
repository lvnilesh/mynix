# Flake Update Cheatsheet

## Your flake inputs

| Input | What it is | Follows nixpkgs? |
|-------|-----------|------------------|
| nixpkgs | Core packages (nixos-unstable) | -- |
| home-manager | Dotfiles/user config manager | Yes |
| hyprland | Wayland compositor | Yes |
| agenix | Secrets management | Yes |
| hermes-agent | NousResearch agent | Yes |

## Check what you have now

```bash
# List all direct inputs (from your flake.nix)
nix flake metadata --json | jq -r ".locks.nodes.root.inputs | keys[]" | sort

# or with python
nix flake metadata --json | python3 -c "
import json, sys
d = json.load(sys.stdin)
for i in sorted(d[\"locks\"][\"nodes\"][\"root\"][\"inputs\"]):
    print(i)"

# Show lock dates for all inputs (including transitive)
nix flake metadata

# Compact table: input names + lock dates
jq -r ".nodes | to_entries[] | select(.value.locked.lastModified) | \"\(.key)\t\(.value.locked.lastModified)\"" flake.lock | while read name ts; do printf "%-25s %s\n" "$name" "$(date -d @$ts +%Y-%m-%d 2>/dev/null || date -r $ts +%Y-%m-%d)"; done | sort

# or with python
cat flake.lock | python3 -c "
import json, sys, datetime
d = json.load(sys.stdin)
for n, v in sorted(d[\"nodes\"].items()):
    if \"locked\" in v and \"lastModified\" in v[\"locked\"]:
        ts = datetime.datetime.fromtimestamp(v[\"locked\"][\"lastModified\"]).strftime(\"%Y-%m-%d\")
        print(f\"{n:25s} {ts}\")"
```

## Update strategies

### Update everything (nuclear option)

```bash
nix flake update
```

Updates ALL inputs. Can break things if multiple inputs change at once.

### Update only nixpkgs (safest, most common)

```bash
nix flake update nixpkgs
```

Since home-manager, hyprland, agenix, and hermes-agent all have
`inputs.nixpkgs.follows = "nixpkgs"`, they automatically use
whatever nixpkgs you pin. This is usually all you need.

### Update specific inputs (pick and choose)

```bash
# Just nixpkgs and home-manager
nix flake update nixpkgs home-manager

# Just hyprland (pulls its sub-inputs too)
nix flake update hyprland

# Everything EXCEPT hermes-agent
nix flake update nixpkgs home-manager hyprland agenix
```

### Pin an input to a specific commit

```bash
# Pin nixpkgs to an exact commit (e.g. known good)
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/COMMIT_HASH

# Pin hyprland to a specific tag/release
nix flake lock --override-input hyprland github:hyprwm/hyprland/v0.54.0
```

### Roll back after a bad update

```bash
# Undo the flake.lock change
git checkout flake.lock

# Or revert to previous NixOS generation
sudo nixos-rebuild switch --rollback
```

## Build and apply

```bash
# Build without switching (test first)
sudo nixos-rebuild build --flake .#asus

# Build and switch
sudo nixos-rebuild switch --flake .#asus

# Build and switch on next boot only (safer)
sudo nixos-rebuild boot --flake .#asus
```

## Diff before you commit

```bash
# See what changed in flake.lock
git diff flake.lock

# See what packages changed
nix store diff-closures /run/current-system ./result

# List generations
sudo nix-env --list-generations -p /nix/var/nix/profiles/system
```

## Recommended workflow

1. `git stash` or commit your nix changes first
2. `nix flake update nixpkgs` (or whichever inputs)
3. `sudo nixos-rebuild build --flake .#asus` (build only, don't switch)
4. If build succeeds: `sudo nixos-rebuild switch --flake .#asus`
5. Test your system
6. If good: `git add flake.lock && git commit -m "update nixpkgs"`
7. If bad: `git checkout flake.lock && sudo nixos-rebuild switch --rollback`
