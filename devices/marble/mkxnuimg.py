#!/usr/bin/env python3
"""Package Mu-Silicium Marble UEFI and an XNUP payload for fastboot boot."""
import argparse
import gzip
import os
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MU = Path(os.environ.get("MU_DIR", ROOT / "Mu-Silicium-marble"))
FD_BASE = 0xA7100000
FD_SIZE = 0x300000
PAYLOAD_BASE = 0xF2000000
PAYLOAD_MAX = 0x04000000
BOOT_HEADER_VERSION = 1  # Keep the legacy load-address fields for fastboot boot.

parser = argparse.ArgumentParser()
parser.add_argument("-p", "--payload", help="XNUP payload; omit to boot the UEFI/XNULoader only")
parser.add_argument("-o", "--output", default=str(ROOT / "marble-boot.img"))
parser.add_argument("--mode", default="RELEASE")
args = parser.parse_args()

fd_path = MU / f"Build/marblePkg/{args.mode}_CLANGPDB/FV/SILICIUM_UEFI.fd"
if not fd_path.is_file():
    raise SystemExit(f"UEFI image not found: {fd_path}; build marblePkg first")

shim_dir = MU / "BootShim"
subprocess.check_call([
    "clang", "--target=aarch64-linux-gnu", "-c", "BootShim.S", "-o", "BootShim.elf",
    "-DREQUIRES_KERNEL_HEADER=1", f"-DFD_BASE={FD_BASE:#x}", f"-DFD_SIZE={FD_SIZE:#x}",
    f"-DPAYLOAD_BASE={PAYLOAD_BASE:#x}",
], cwd=shim_dir)

# BootShim.S is a single .text section. Extract it directly so packaging does not
# depend on the host's llvm-objcopy shared-library version.
elf = (shim_dir / "BootShim.elf").read_bytes()
if elf[:6] != b"\x7fELF\x02\x01":
    raise SystemExit("BootShim build did not produce little-endian ELF64")
shoff = struct.unpack_from("<Q", elf, 40)[0]
shentsize, shnum, shstrndx = struct.unpack_from("<HHH", elf, 58)
sections = [struct.unpack_from("<IIQQQQIIQQ", elf, shoff + i * shentsize) for i in range(shnum)]
strings = sections[shstrndx]
names = elf[strings[4]:strings[4] + strings[5]]
text_section = next(s for s in sections if names[s[0]:].split(b"\0", 1)[0] == b".text")
shim = elf[text_section[4]:text_section[4] + text_section[5]]
if not shim:
    raise SystemExit("BootShim .text section is empty")

fd = fd_path.read_bytes()
if len(fd) != FD_SIZE:
    raise SystemExit(f"unexpected Marble UEFI FD size: {len(fd):#x}, expected {FD_SIZE:#x}")
payload = Path(args.payload).read_bytes() if args.payload else b""
if payload and (payload[:4] != b"XNUP" or len(payload) > PAYLOAD_MAX - 0x1000):
    raise SystemExit("payload is not a valid Marble-sized XNUP container")

blob = shim + fd + payload
blob += b"\0" * (-len(blob) % 16)
kernel_path = Path(args.output + ".kernel~")
kernel_path.write_bytes(gzip.compress(blob, 6) + (MU / "Resources/DTBs/marble.dtb").read_bytes())
try:
    subprocess.check_call([
        sys.executable, str(MU / "Resources/Scripts/mkbootimg.py"),
        "--kernel", str(kernel_path), "--ramdisk", str(MU / "Resources/ramdisk"),
        "--header_version", str(BOOT_HEADER_VERSION), "-o", args.output,
    ])
    image = Path(args.output).read_bytes()
    version = struct.unpack_from("<I", image, 40)[0]
    kernel_addr = struct.unpack_from("<I", image, 12)[0]
    if version != BOOT_HEADER_VERSION or kernel_addr != 0x10008000:
        raise SystemExit(
            f"unexpected fastboot boot header: version={version}, kernel_addr={kernel_addr:#x}"
        )
finally:
    kernel_path.unlink(missing_ok=True)
print(f"{args.output}: {Path(args.output).stat().st_size} bytes; header=v{BOOT_HEADER_VERSION} UEFI={len(fd)} payload={len(payload)}")
