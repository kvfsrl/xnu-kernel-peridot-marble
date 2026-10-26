#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HERE="$ROOT/devices/marble/uefi"
MU="${MU_DIR:-$ROOT/Mu-Silicium-marble}"

if [[ ! -d "$MU/.git" ]]; then
	git clone --filter=blob:none https://github.com/Project-Silicium/Mu-Silicium.git "$MU"
	git -C "$MU" checkout --detach "$(cat "$HERE/BASE")"
	git -C "$MU" submodule update --init --recursive
fi

if ! git -C "$MU" apply --check "$HERE/mu-silicium.patch"; then
	echo "Marble UEFI patch does not apply cleanly to $MU" >&2
	exit 1
fi
git -C "$MU" apply --whitespace=nowarn "$HERE/mu-silicium.patch"
install -m 0644 "$HERE/files/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.c" \
	"$MU/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.c"
install -m 0644 "$HERE/files/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.h" \
	"$MU/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.h"
install -m 0644 "$HERE/files/Resources/Configs/marble.toml" "$MU/Resources/Configs/marble.toml"
echo "Applied HackiOS XNUP handoff to Mu-Silicium Marble."
