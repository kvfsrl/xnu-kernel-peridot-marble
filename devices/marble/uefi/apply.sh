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

if git -C "$MU" apply --check "$HERE/mu-silicium.patch" >/dev/null 2>&1; then
	git -C "$MU" apply --whitespace=nowarn "$HERE/mu-silicium.patch"
elif ! git -C "$MU" apply --reverse --check "$HERE/mu-silicium.patch" >/dev/null 2>&1; then
	echo "Marble UEFI patch does not apply cleanly to $MU" >&2
	exit 1
fi
install -m 0644 "$HERE/files/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.c" \
	"$MU/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.c"
install -m 0644 "$HERE/files/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.h" \
	"$MU/Silicon/Silicium/SiliciumPkg/Library/BootManagerLib/XnuLoader.h"
install -m 0644 "$HERE/files/Resources/Configs/marble.toml" "$MU/Resources/Configs/marble.toml"
install -D -m 0644 "$HERE/files/Platforms/Xiaomi/marble/AcpiTables.inf" \
	"$MU/Silicium-ACPI/Platforms/Xiaomi/marble/AcpiTables.inf"
python3 - "$MU/Platforms/Xiaomi/marblePkg/Library/MemoryMapLib/MemoryMapLib.c" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
anchor = '  {"TZApps Reserved",    0xEA000000, 0x07400000, AddMem, MEM_RES, UNCACHEABLE, Reserv, UNCACHED_UNBUFFERED_XN},\n'
region = '  {"XNU Payload",        0xF2000000, 0x04000000, AddMem, SYS_MEM, SYS_MEM_CAP, Reserv, WRITE_BACK_XN},\n'
if region not in source:
    if anchor not in source:
        raise SystemExit(f"cannot reserve the Marble XNUP buffer in {path}")
    source = source.replace(anchor, anchor + region, 1)
    path.write_text(source)
PY
python3 - "$MU/Platforms/Xiaomi/marblePkg/DeviceBuild.py" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text()
anchor = '        logging.debug ("PlatformBuilder SetPlatformEnv")\n'
setting = '        self.env.SetValue ("EDK_BUILD_CMD", os.environ.get("EDK_BUILD_CMD", "build"), "Marble build wrapper")\n'
workspace = '    WorkspaceRoot = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))\n'
workspace_alias = '    WorkspaceRoot = os.environ.get("MU_ALIAS", os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))))\n'
if setting not in source:
    if anchor not in source:
        raise SystemExit(f"cannot add path-safe EDK2 command to {path}")
    source = source.replace(anchor, anchor + setting, 1)
if workspace_alias not in source:
    if workspace not in source:
        raise SystemExit(f"cannot use the no-space Mu workspace alias in {path}")
    source = source.replace(workspace, workspace_alias, 1)
path.write_text(source)
PY
echo "HackiOS XNUP handoff and Marble ACPI table manifest are present in Mu-Silicium."
