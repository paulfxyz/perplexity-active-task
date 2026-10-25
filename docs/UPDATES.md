# In-app updates

Active Task 2.0.0 introduces a small native GitHub Releases updater. **Install 2.0.0 manually once if you are coming from 1.x**; old binaries cannot use an updater they do not contain.

## Check and install

Choose **Active Task > Check for Updates…**, the menu-bar action, the sliders menu action, or the button in Settings. The dialog reports whether a newer stable version is available.

Automatic checks are enabled by default, about fifteen seconds after launch and every six hours while the app runs. They can be disabled in Settings, do not wake the Mac, do not download an update automatically, and do not interrupt you with a background installation prompt. Availability is shown in Settings; use a manual check to open the confirmation dialog.

Choose **Download & Restart** to approve downloading, replacing, and reopening the application. Download progress and verification status appear in Settings. Cancel the offer with Later, or inspect GitHub Releases first.

## Verification and installation

The updater:

- **Checks the source:** Uses only this repository's public stable Releases endpoint, exact expected asset path, strict numeric versions, a bounded size, and a valid GitHub SHA-256 digest.
- **Controls networking:** Uses an ephemeral, cookieless client without stored URL credentials or cache. Every redirect must remain HTTPS on an explicit GitHub host.
- **Verifies the download:** Compares the actual byte count and SHA-256 before extraction.
- **Checks the archive:** Rejects traversal, unexpected roots, symlinks, and unsupported layouts before unpacking.
- **Checks the app:** Requires `com.paulfleury.activetask`, the advertised version, a compatible minimum macOS version, an executable named `ActiveTask`, Apple silicon and Intel architectures, and a valid code-signature integrity check.
- **Stages locally:** Creates a mode-0700 hidden sibling folder, copies the current app's helper there, and does not alter the installed app while it is running.
- **Confirms the swap:** Waits for the old PID to exit, rechecks bundle identity/version and signature, obtains a local lock, moves the old app into backup, moves the candidate into place, and runs `open` on it.

There is no sudo, password prompt, quarantine removal, Gatekeeper modification, or privileged daemon. A non-writable location, mounted volume, App Translocation path, symlinked bundle, same/older version, or invalid candidate is refused.

## Recovery

The installer retains a hidden sibling directory named `.active-task-update-<UUID>`, containing `Previous Active Task.app`, the helper, and a mode-0600 `update.log`. Finder's Go to Folder can open the parent directory; show hidden files to inspect it.

If the immediate swap or `open` command fails, the helper restores and attempts to reopen the previous app. A failed candidate is retained as `Failed Active Task.app` for inspection.

If the new app launches but subsequently crashes or fails to sign in, quit it and manually restore the previous app from that folder. The updater does not run a post-launch health handshake or monitor website behavior.

Backups are not pruned automatically. After verifying a new version and keeping any backup you want, you may remove that generated staging folder yourself; do not delete your WebKit data store or preferences as part of an update.

## Trust and limitations

The app is still ad-hoc signed, **not Developer ID signed or Apple-notarized**. A valid ad-hoc signature checks bundle integrity, not a verified publisher identity. The hash is obtained from the same GitHub release as the ZIP, not from a separately pinned cryptographic signing key.

The trust boundary is the repository account, GitHub release infrastructure, HTTPS, and the currently installed local app. This is not Sparkle or an independent signed-feed updater. Read [Security](../SECURITY.md) before deciding whether to use it.

Checksum, metadata, network, validation, and permission errors leave the existing app untouched and offer GitHub Releases as a manual fallback. A stale lock after a forced machine shutdown may require inspecting and removing only the generated `.active-task-update-lock` directory after confirming no update is active.

## Tests

Native tests exercise semantic-version comparisons, URL and metadata rejection, checksum/size rejection, unsafe archive names, bundle validation, and a real harmless universal fixture app's replacement/reopen. A disposable helper copy replaces its single launch command with a forced failure to exercise rollback, without adding a test bypass to the shipped helper.

A separate native network probe reads the real stable feed, follows allowed redirects, downloads the current public ZIP, and checks its digest without installing it. These tests do not replace real-Mac Gatekeeper, permissions, or authenticated website acceptance.
