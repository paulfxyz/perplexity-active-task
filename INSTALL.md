# Install Active Task

Active Task 1.1.0 supports macOS 13 or later on Apple silicon and Intel. Download the universal ZIP from [GitHub Releases](https://github.com/paulfxyz/perplexity-active-task/releases/latest); there is no installer package or automatic updater.

## First installation

1. Download `Active-Task-macOS-universal.zip` and extract it.
2. Move `Active Task.app` to Applications and open it.
3. If macOS blocks the community build, first try opening it, then use System Settings > Privacy & Security > Open Anyway if your Mac offers that action. Verify the download and only approve software you trust.
4. Sign into Perplexity in the app. Open Settings with ⌘, to adjust floating, dimming, sidebar hiding, and inactive opacity.

The app is ad-hoc signed, not Developer ID signed or Apple-notarized. Signature integrity is not an Apple-verified publisher identity. Do not globally disable Gatekeeper, remove your organization's security policies, or run administrator commands to install this app. A managed Mac may not permit this community build.

## Verify your download

Download `SHA256SUMS.txt` alongside the ZIP from the same release, then run this in that directory:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

This checks that your file matches that release's checksum; it does not substitute for independent trust in the publisher or Apple notarization.

## Update from 1.0.0

Quit Active Task using ⌘Q, replace the app in Applications, and reopen. Keep the same application name and bundle identifier, `com.paulfleury.activetask`; the app continues using the associated preferences and WebKit data store.

The 1.1.0 opacity menu is exactly 5%, 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%, and 95%. Older values migrate to the nearest supported level, with ties choosing the lower one: 65% becomes 60%, and 35% becomes 30%. Dimming remains disabled if it was disabled before the update.

## Sign-in troubleshooting

The app and your ordinary browser have different cookies. Signing into Safari, Comet, or another browser does not authenticate the embedded WebKit view.

Perplexity and identity providers control which sign-in flows work. Embedded-browser Google, Apple, SSO, or verification may be rejected; use email/code login if Perplexity offers it. An email magic link may open your default browser instead of the app. Return to the app and enter a code if available; this project does not bypass those restrictions.

Use the sidebar toggle to restore access to account controls. If no supported sign-in method works, use the website in your browser and report the failing flow without sending account secrets.

## Window troubleshooting

- **Almost invisible:** Click where the window is to restore full opacity, or reopen it from the menu bar and disable dimming in Settings.
- **Missing after close:** The activity-wave menu-bar icon restores it. Closing the window does not quit the app.
- **Unexpected fading:** Opening Settings moves focus away from the task window. That is inactive dimming working as configured.
- **Sidebar still visible:** Turn hiding off, use the website's collapse control if available, then report the issue. Site markup changes can invalidate known hooks.
- **Not above everything:** Floating covers ordinary windows, not necessarily system dialogs, elevated windows, or every Spaces/full-screen layout.
- **Blank or disconnected:** Check connectivity and press ⌘R. Use ⌘B to open the current page in your browser for comparison.

## Build it yourself

On a Mac with Xcode Command Line Tools:

```sh
git clone https://github.com/paulfxyz/perplexity-active-task.git
cd perplexity-active-task
bash scripts/build.sh
open "build/Active Task.app"
```

The output is a universal, ad-hoc-signed application. Building locally does not grant Perplexity access or change identity-provider restrictions.
