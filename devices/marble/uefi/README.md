# Marble UEFI and XNU loader

This overlays the XNUP payload handoff onto Project Silicium's Mu-Silicium
revision in `BASE`, which already contains the Marble UEFI platform package.

```sh
devices/marble/uefi/apply.sh
python3 -m venv .venv-marble
. .venv-marble/bin/activate
pip install -r Mu-Silicium-marble/pip-requirements.txt
cd Mu-Silicium-marble
python3 build_uefi.py -d marble -r RELEASE
cd ../..
xnuloader/build.sh
```

The UEFI build requires Mu-Silicium's submodules and device-binary package.
Firmware binaries remain dependencies of Mu-Silicium and are not copied into
this repository.

To package the UEFI image for `fastboot boot`, build the XNU kernel and loader
payload first, then run `devices/marble/mkxnuimg.py -p run-payload.bin -o
marble-boot.img`.
