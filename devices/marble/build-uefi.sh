#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
HERE="$ROOT/devices/marble"
MU="${MU_DIR:-$ROOT/Mu-Silicium-marble}"
OUT="${MARBLE_OUT:-$HERE/out}"
VENV="${MARBLE_VENV:-$ROOT/.venv-marble}"
MU_ALIAS="$ROOT/.marble-mu"

if [[ -L "$MU_ALIAS" ]]; then
	[[ "$(readlink "$MU_ALIAS")" == "$MU" ]] || { echo "$MU_ALIAS points somewhere else" >&2; exit 1; }
elif [[ -e "$MU_ALIAS" ]]; then
	echo "$MU_ALIAS exists and is not the expected Mu-Silicium link" >&2
	exit 1
else
	ln -s "$MU" "$MU_ALIAS"
fi

MU_DIR="$MU" "$HERE/uefi/apply.sh"
python3 -m venv "$VENV"
"$VENV/bin/pip" install -q -r "$MU/pip-requirements.txt"
(cd "$MU_ALIAS" && PATH="$VENV/bin:$HERE/tools:$PATH" \
	MU_ALIAS="$MU_ALIAS" \
	EDK_BUILD_CMD="$HERE/tools/edk2-build" \
	"$VENV/bin/python" "$MU_ALIAS/build_uefi.py" -d marble -r RELEASE)
mkdir -p "$OUT"
MU_DIR="$MU" python3 "$HERE/mkxnuimg.py" -o "$OUT/marble-uefi.img"
echo "Loader-only Marble boot image: $OUT/marble-uefi.img"
