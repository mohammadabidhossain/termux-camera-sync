# termux-camera-sync

Automatically backs up my Android phone's Camera folder to a local server/NAS every night, using Termux running directly on the phone. No cloud, no third-party service — everything stays on my home LAN.

## What it does

Every night at **10:00 PM**, a cron job wakes up, takes a wake-lock so Android doesn't kill it mid-transfer, and runs `rsync` over SSH to mirror `DCIM/Camera` on the phone into `/mnt/mydata/pictures/Pixel 6 pics and videos/` on a server/NAS (`192.168.2.200`, a private LAN address) — the existing photo library folder for this phone. Only new/changed files are transferred after the first run.

## Components

- `bin/sync_camera.sh` — the sync script cron runs. Wake-locks, rsyncs `~/storage/dcim/Camera/` to the server/NAS over SSH, logs to `~/sync_camera.log`.
- `termux-boot/start-services.sh` — runs on every device boot (via the [Termux:Boot](https://github.com/termux/termux-boot) app), starting the `termux-services` daemon so `crond` is alive even if Termux was never manually opened after a reboot.

## Setup (from scratch)

1. **Install Termux** (F-Droid build, not Play Store — the Play Store build is outdated/deprecated).
2. **Grant storage access:**
   ```
   termux-setup-storage
   ```
   Accept the Android permission prompt. This exposes `~/storage/dcim`, `~/storage/pictures`, etc.
3. **Install packages:**
   ```
   pkg install openssh rsync cronie termux-services
   ```
4. **Set up passwordless SSH to the server/NAS:**
   ```
   ssh-keygen -t ed25519
   ssh-copy-id user@192.168.2.200
   ```
   Add a `Host` alias in `~/.ssh/config` for convenience:
   ```
   Host minipc
       HostName 192.168.2.200
       User youruser
       IdentityFile ~/.ssh/id_ed25519
   ```
5. **Drop in `bin/sync_camera.sh`** (this repo), adjust `SRC`/`DEST` paths if needed, `chmod +x` it.
6. **Start the service daemon and enable crond:**
   ```
   export SVDIR=$PREFIX/var/service
   (service-daemon start &)
   sv-enable crond
   ```
7. **Schedule the nightly job:**
   ```
   crontab -e
   ```
   Add:
   ```
   0 22 * * * /data/data/com.termux/files/home/bin/sync_camera.sh
   ```
8. **Install [Termux:Boot](https://github.com/termux/termux-boot)** (same source as Termux — F-Droid), open it once to register with Android, then place `termux-boot/start-services.sh` (this repo) at `~/.termux/boot/start-services.sh`.
9. **Disable battery optimization** for both Termux and Termux:Boot: Android Settings → Apps → [app] → Battery → Unrestricted. On some OEMs (Xiaomi/Oppo/Vivo/Huawei) also enable "Autostart" for both apps. Without this, Android will eventually kill the background service and the nightly sync silently stops.

## Notes

- This is a one-way mirror (phone → server/NAS). Nothing is deleted from the phone.
- Logs land in `~/sync_camera.log` on the phone.
- The server/NAS only needs a standard OpenSSH server running; no special software required on that end.
