#!/usr/bin/env python3
"""Package Mu-Silicium Marble UEFI and an XNUP payload for fastboot boot."""
import argparse
import gzip
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MU = Path(os.environ.get("MU_DIR", ROOT / "Mu-Silicium-marble"))
FD_BASE = 0xA7100000
FD_SIZE = 0x300000
PAYLOAD_BASE = 0xF0000000
PAYLOAD_MAX = 0x04000000

parser = argparse.ArgumentParser()
parser.add_argument("-p", "--payload", required=True)
parser.add_argument("-o", "--output", default=str(ROOT / "marble-boot.img"))
parser.add_argument("--mode", default="RELEASE")
args = parser.parse_args()

fd_path = MU / f"Build/marblePkg/{args.mode}_CLANGPDB/FV/SILICIUM_UEFI.fd"
if not fd_path.is_file():
    raise SystemExit(f"UEFI image not found: {fd_path}; build marblePkg first")

shim_dir = MU / "BootShim"
for name in ("BootShim.elf", "BootShim.bin"):
    try:
        (shim_dir / name).unlink()
    except FileNotFoundError:
        pass
subprocess.check_call([
    "make", "REQUIRES_KERNEL_HEADER=1", f"FD_BASE={FD_BASE:#x}",
    f"FD_SIZE={FD_SIZE:#x}", f"CFLAGS=--target=aarch64-linux-gnu -DPAYLOAD_BASE={PAYLOAD_BASE:#x}",
], cwd=shim_dir)

shim = (shim_dir / "BootShim.bin").read_bytes()
fd = fd_path.read_bytes()
if len(fd) != FD_SIZE:
    raise SystemExit(f"unexpected Marble UEFI FD size: {len(fd):#x}, expected {FD_SIZE:#x}")
payload = Path(args.payload).read_bytes()
if payload[:4] != b"XNUP" or len(payload) > PAYLOAD_MAX - 0x1000:
    raise SystemExit("payload is not a valid Marble-sized XNUP container")

blob = shim + fd + payload
blob += b"\0" * (-len(blob) % 16)
kernel_path = Path(args.output + ".kernel~")
kernel_path.write_bytes(gzip.compress(blob, 6) + (MU / "Resources/DTBs/marble.dtb").read_bytes())
try:
    subprocess.check_call([
        sys.executable, str(MU / "Resources/Scripts/mkbootimg.py"),
        "--kernel", str(kernel_path), "--ramdisk", str(MU / "Resources/ramdisk"),
        "--header_version", "1", "-o", args.output,
    ])
finally:
    kernel_path.unlink(missing_ok=True)
print(f"{args.output}: {Path(args.output).stat().st_size} bytes; UEFI={len(fd)} payload={len(payload)}")
