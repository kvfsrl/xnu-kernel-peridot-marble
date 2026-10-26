#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$ROOT"
ROOT_IMAGE="${MARBLE_ROOT_IMAGE:-userland/root.apfs}"
SYSTEM_IMAGE="${MARBLE_SYSTEM_IMAGE:-userland/system.apfs}"

for image in "$ROOT_IMAGE" "$SYSTEM_IMAGE"; do
	[[ -s "$image" ]] || { echo "Missing image: $image" >&2; exit 1; }
done

# Build the Marble firmware and let xl package its matching XNULoader payload.
./devices/marble/build-uefi.sh
export XL_MKXNUIMG=devices/marble/mkxnuimg.py
export XL_LOADER=xnuloader/loader.efi
PLATFORM=marble ./xnuloader/build.sh

./xl ramdisk "$SYSTEM_IMAGE"
echo "Starting Marble userland with touch enabled; PosterBoard is available on demand."
XL_RAMDISK="$ROOT_IMAGE" \
XL_CMDLINE="bootcpu=7 cpus=8 touchscreen=1 marble_touch=1" \
XL_SECS="${XL_SECS:-600}" XL_FOLLOW="${XL_FOLLOW:-30}" \
	./xl run
