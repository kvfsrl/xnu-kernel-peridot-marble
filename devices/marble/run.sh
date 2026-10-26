#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$ROOT"
BOOT_IMAGE="${MARBLE_BOOT_IMAGE:-devices/marble/out/marble-uefi.img}"
ROOT_IMAGE="${MARBLE_ROOT_IMAGE:-userland/root.apfs}"
SYSTEM_IMAGE="${MARBLE_SYSTEM_IMAGE:-userland/system.apfs}"

for image in "$BOOT_IMAGE" "$ROOT_IMAGE" "$SYSTEM_IMAGE"; do
	[[ -s "$image" ]] || { echo "Missing image: $image" >&2; exit 1; }
done

state=$(./xl state)
if [[ "$state" == fastboot ]]; then
	fastboot boot "$BOOT_IMAGE"
	for _ in $(seq 1 60); do
		state=$(./xl state)
		[[ "$state" == loader ]] && break
		sleep 2
	done
fi
[[ "$state" == loader ]] || { echo "Phone is not in XNULoader (state: $state)." >&2; exit 1; }

./xl ramdisk "$SYSTEM_IMAGE"
echo "Starting Marble userland with touch enabled; PosterBoard is available on demand."
XL_RAMDISK="$ROOT_IMAGE" \
XL_CMDLINE="bootcpu=7 cpus=8 touchscreen=1 marble_touch=1" \
XL_SECS="${XL_SECS:-600}" XL_FOLLOW="${XL_FOLLOW:-30}" \
	./xl run
