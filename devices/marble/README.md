# POCO F5 / Redmi Note 12 Turbo (`marble`)

This port targets Qualcomm SM7475-AB and the Adreno 725. It starts from the
upstream HackiOS kernel repository and the device's Mu-Silicium platform data.

## Bring-up order

1. Build and boot the Marble UEFI plus XNU loader from RAM.
2. Verify the Marble touch controller and map it into `/dev/hakios-touch`.
3. Build the iOS userland image with PosterBoard enabled and verify a live
   wallpaper from SpringBoard.

Never flash the generated image. The intended device path is `fastboot boot`.
The XNU image needs firmware extracted from the target phone; firmware and iOS
images are not stored in this repository.

## UEFI/XNU loader

`uefi/BASE` pins the Mu-Silicium revision that includes `marblePkg` and the
Marble device tree. `uefi/apply.sh` overlays HackiOS's XNUP handoff on that
platform. `build-uefi.sh` builds a loader-only Android boot image for
`fastboot boot`; it never flashes the phone.

The public Marble DTBO maps the primary touch controller to FocalTech FT3658U
on QUPv3 SE4 (`0x990000`), with GPIO 20 reset, GPIO 21 interrupt, and a
1080×2340 panel. `marble_touch=1` selects this wiring and a conservative
GPIO-driven SPI path. It does not reset the controller or upload firmware.
The report format still needs validation against a live phone.

`build-userland.sh` includes iOS launch angels on demand (`REST=1`), including
PosterBoard when its executable is present in the selected system image.
Wallpaper rendering still needs verification on the target phone.
