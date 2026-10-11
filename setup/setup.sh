#!/usr/bin/env bash
set -euo pipefail

# Start dependency setup; bootstrap LuaJIT if missing, then run the Lua steps.
# Follow launcher symlinks; neither the checkout name nor current directory matters.
setup_dir="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"

if (( $# )); then
    printf 'Usage: %s\n' "$0" >&2
    exit 1
fi

# Build AUR packages as a regular user with configured sudo access.
if (( EUID == 0 )); then
    printf 'Run as your normal user with sudo access.\n' >&2
    exit 1
fi
command -v pacman >/dev/null
command -v sudo >/dev/null

# Use a full upgrade when refreshing Arch repositories, avoiding partial upgrades.
if ! command -v luajit >/dev/null; then
    sudo pacman -Syu --needed luajit
fi

exec luajit "$setup_dir/install-required-deps.lua"
