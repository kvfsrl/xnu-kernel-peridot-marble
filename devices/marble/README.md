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
platform. See `uefi/README.md` for the build command.

The UEFI DTB is the public Marble platform DTB used by Mu-Silicium. Touch
controller details still need confirmation from the phone's Android DTB; the
Android DTB must be pulled from the actual Marble device before enabling a
controller-specific address or bus in XNU.
