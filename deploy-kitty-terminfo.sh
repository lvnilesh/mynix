#!/usr/bin/env bash
# deploy-kitty-terminfo.sh
# Copy (or update) the xterm-kitty terminfo entry to one or more remote hosts.
# Root not required on remote: installs into ~/.terminfo.
#
# Features:
#  - Detects if remote already has working xterm-kitty; skips unless --force
#  - Supports host list via args or --hosts-file file (one host per line, comments/# allowed)
#  - Parallel mode with --parallel N (default 1)
#  - Dry run support via --dry-run
#  - Verbose output via -v / --verbose
#
# Examples:
#   ./deploy-kitty-terminfo.sh imac.cg.home.arpa
#   ./deploy-kitty-terminfo.sh host1 host2 host3
#   ./deploy-kitty-terminfo.sh --hosts-file hosts.txt --parallel 4
#   ./deploy-kitty-terminfo.sh --force imac
#   ./deploy-kitty-terminfo.sh --dry-run imac
#
# hosts.txt example:
#   # personal machines
#   imac.cg.home.arpa
#   nas.local
#
set -euo pipefail
IFS=$'\n\t'

PARALLEL=1
FORCE=0
DRY=0
VERBOSE=0
HOSTS_FILE=""

die() { echo "[ERR] $*" >&2; exit 1; }
log() { echo "[INFO] $*"; }
vecho() { (( VERBOSE )) && echo "[DBG] $*" >&2 || true; }
usage() {
  sed -n '1,60p' "$0" | grep -E '^#' | cut -c3-
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

while (( $# )); do
  case "$1" in
    -h|--help) usage; exit 0;;
    --hosts-file) HOSTS_FILE=${2:-}; shift 2;;
    --parallel) PARALLEL=${2:-1}; shift 2;;
    --force) FORCE=1; shift;;
    --dry-run) DRY=1; shift;;
    -v|--verbose) VERBOSE=1; shift;;
    --) shift; break;;
    -*) die "Unknown option: $1";;
    *) break;;
  esac
done

HOSTS=("$@")
if [[ -n "$HOSTS_FILE" ]]; then
  [[ -f "$HOSTS_FILE" ]] || die "Hosts file not found: $HOSTS_FILE"
  while IFS= read -r line; do
    line="${line%%#*}" # strip comments
    line="${line// /}" # strip spaces
    [[ -n "$line" ]] || continue
    HOSTS+=("$line")
  done < "$HOSTS_FILE"
fi
[[ ${#HOSTS[@]} -gt 0 ]] || die "No hosts specified"

have_cmd infocmp || die "infocmp not found (ncurses terminfo tools required)"
have_cmd ssh || die "ssh not found"
have_cmd tic || vecho "Local 'tic' not strictly required (we compile remotely)."

# Acquire terminfo once
vecho "Dumping local xterm-kitty terminfo"
TERMINF_SRC=$(infocmp -x xterm-kitty 2>/dev/null || true)
[[ -n "$TERMINF_SRC" ]] || die "Local system lacks xterm-kitty terminfo. Launch kitty then retry, or install kitty-terminfo."

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
printf '%s\n' "$TERMINF_SRC" > "$work_dir/xterm-kitty.src"

# Function to process a single host
process_host() {
  local host=$1
  local tag="[$host]"
  echo "$tag Starting"
  if (( DRY )); then
    echo "$tag DRY-RUN would deploy terminfo"; return 0
  fi
  # Test existing
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$host" 'infocmp xterm-kitty >/dev/null 2>&1'; then
    if (( FORCE )); then
      echo "$tag Found existing terminfo, forcing update"
    else
      echo "$tag Already present, skipping (use --force to override)"; return 0
    fi
  fi
  # Deploy via stdin pipe
  if ! printf '%s\n' "$TERMINF_SRC" | ssh -o BatchMode=yes "$host" 'tic -x - >/dev/null 2>&1'; then
    echo "$tag FAILED to install terminfo" >&2; return 1
  fi
  # Validate
  if ssh -o BatchMode=yes "$host" 'infocmp xterm-kitty >/dev/null 2>&1'; then
    echo "$tag Installed successfully"
  else
    echo "$tag Verification failed" >&2; return 1
  fi
}

# Parallel dispatcher
FAIL=0
if (( PARALLEL > 1 )); then
  have_cmd xargs || die "xargs required for parallel mode"
  export -f process_host
  export TERMINF_SRC
  # shellcheck disable=SC2016
  printf '%s\n' "${HOSTS[@]}" | xargs -I{} -P "$PARALLEL" bash -c 'process_host "$@"' _ {}
else
  for h in "${HOSTS[@]}"; do
    process_host "$h" || FAIL=1
  done
fi

exit $FAIL
