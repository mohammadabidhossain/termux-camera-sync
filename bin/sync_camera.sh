#!/data/data/com.termux/files/usr/bin/bash
# Nightly sync of phone Camera folder to private storage server or NAS.(for me it's mini pc) 
# Runs from cron; keep this script idempotent and safe to re-run.

set -euo pipefail

SRC="$HOME/storage/dcim/Camera/"
DEST="minipc:/mnt/mydata/pictures/Pixel 6 pics and videos/"
LOG="$HOME/sync_camera.log"

exec >>"$LOG" 2>&1

echo "===== $(date '+%Y-%m-%d %H:%M:%S') sync start ====="

termux-wake-lock

cleanup() {
    termux-wake-unlock
}
trap cleanup EXIT

if [ ! -d "$SRC" ]; then
    echo "ERROR: source $SRC not accessible (storage permission or SD card issue)"
    exit 1
fi

rsync -av --stats \
    -e "ssh -o ConnectTimeout=10 -o BatchMode=yes" \
    "$SRC" "$DEST"

echo "===== $(date '+%Y-%m-%d %H:%M:%S') sync done ====="
