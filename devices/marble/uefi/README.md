# Marble UEFI and XNU loader

This overlays the XNUP payload handoff onto Project Silicium's Mu-Silicium
revision in `BASE`, which already contains the Marble UEFI platform package.

```sh
MU_DIR=/path/to/Mu-Silicium devices/marble/build-uefi.sh
```

The script checks out the pinned platform patch, builds Mu-Silicium's Marble
package and BootShim, then creates `devices/marble/out/marble-uefi.img` without
an XNUP payload. The image starts UEFI/XNULoader so the host can upload a kernel
and ramdisks through `xl`. Firmware binaries remain dependencies of Mu-Silicium
and are not copied into this repository.

The fastboot image uses Android boot header v1 to preserve the legacy kernel
load address fields. Do not use v4 here: this path boots a standalone shim with
an appended DTB, not a GKI boot/vendor_boot pair.

Run `devices/marble/build-userland.sh` to create the APFS images with
PosterBoard's launch angel included, then `devices/marble/run.sh` from stock
fastboot. The phone must already be unlocked for `fastboot boot`.
