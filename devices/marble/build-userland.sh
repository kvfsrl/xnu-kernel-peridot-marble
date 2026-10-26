#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$ROOT"
REST=1 userland/build.sh

angel="userland/root/LaunchDaemons/com.apple.PosterBoard.plist"
if [[ ! -s "$angel" ]]; then
	echo "PosterBoard launch angel is missing; check that the selected iOS system image contains its executable." >&2
	exit 1
fi
echo "Built userland/root.apfs and userland/system.apfs; PosterBoard launch angel is present."
