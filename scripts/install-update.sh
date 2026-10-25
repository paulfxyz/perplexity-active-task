#!/bin/bash
# Unprivileged, confirmed updater. Never sudo, clear quarantine, or alter Gatekeeper.
set -euo pipefail
umask 077
[[ "$#" -eq 7 ]] || exit 1
PID="$1"
TARGET="$2"
CANDIDATE="$3"
STAGE="$4"
OLD_VERSION="$5"
NEW_VERSION="$6"
# Reserved argument guards accidental invocation of an incompatible helper.
[[ "$7" == "active-task-update-v1" ]] || exit 1
BACKUP="$STAGE/Previous Active Task.app"
PARENT="$(dirname "$TARGET")"
LOCK="$PARENT/.active-task-update-lock"
[[ "$PID" =~ ^[0-9]+$ ]] || exit 1
[[ "$OLD_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
[[ "$TARGET" == */"Active Task.app" && "$CANDIDATE" == "$STAGE/Active Task.app" ]] || exit 1
[[ "$(dirname "$STAGE")" == "$PARENT" && "$(basename "$STAGE")" == .active-task-update-* ]] || exit 1
[[ -d "$TARGET" && -d "$CANDIDATE" && -d "$STAGE" && ! -L "$TARGET" && ! -L "$CANDIDATE" && ! -L "$STAGE" ]] || exit 1
[[ ! -e "$BACKUP" && "$TARGET" != *"/AppTranslocation/"* ]] || exit 1
for ((i=0; i<60; i++)); do
  if ! kill -0 "$PID" 2>/dev/null; then break; fi
  sleep 1
done
if kill -0 "$PID" 2>/dev/null; then echo "Update cancelled: app did not quit."; exit 1; fi
/bin/mkdir "$LOCK" || { echo "Another update holds the lock. No app was replaced."; exit 1; }
cleanup() { /bin/rmdir "$LOCK" 2>/dev/null || true; }
trap cleanup EXIT
rollback() {
  trap - ERR INT TERM HUP
  echo "Update failed; restoring the previous app."
  if [[ -d "$BACKUP" ]]; then
    if [[ -e "$TARGET" ]]; then /bin/mv "$TARGET" "$STAGE/Failed Active Task.app"; fi
    /bin/mv "$BACKUP" "$TARGET"
    /usr/bin/open "$TARGET" || true
  elif [[ -d "$TARGET" ]]; then
    /usr/bin/open "$TARGET" || true
  fi
  exit 1
}
trap rollback ERR INT TERM HUP
read_info() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist"; }
[[ "$(read_info "$TARGET" CFBundleIdentifier)" == "com.paulfleury.activetask" ]]
[[ "$(read_info "$TARGET" CFBundleShortVersionString)" == "$OLD_VERSION" ]]
[[ "$(read_info "$CANDIDATE" CFBundleIdentifier)" == "com.paulfleury.activetask" ]]
[[ "$(read_info "$CANDIDATE" CFBundleShortVersionString)" == "$NEW_VERSION" ]]
/usr/bin/codesign --verify --deep --strict "$CANDIDATE"
/bin/mv "$TARGET" "$BACKUP"
/bin/mv "$CANDIDATE" "$TARGET"
/usr/bin/open -n "$TARGET"
trap - ERR INT TERM HUP
echo "Update installed. Previous app retained at: $BACKUP"
