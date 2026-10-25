# Active Task

A tiny native macOS window for **Perplexity Computer's active tasks**, made for Paul. It opens directly to [the active-task list](https://www.perplexity.ai/computer/tasks?status=active), remembers its size and position, and stays out of the way.

Independent personal utility, not an official Perplexity product.

## Download and install

Get `Active-Task-macOS-universal.zip` from this private repository's [Releases](https://github.com/paulfxyz/perplexity-active-task/releases). It supports Apple silicon and Intel Macs running macOS 13 or later.

Unzip, move **Active Task.app** to Applications, and open it. This personal build is ad-hoc signed, **not Apple-notarized**. If macOS blocks it, first try opening it, then use System Settings > Privacy & Security > Open Anyway, only after verifying you downloaded this repository's build. Alternatively, build locally using the script below. No security settings need to be globally disabled.

## Use it

- **Sign in:** Log in directly to Perplexity inside the app. WebKit stores this app's cookies and session locally across launches. It has its own session, separate from Comet or Safari; it never imports your browser cookies.
- **Small and resizable:** Starts at 520 × 700, resizes down to 360 × 360, and remembers its window frame. Use View > Zoom Out if you want denser content.
- **Always on Top:** Enabled by default. Toggle it from the sliders button.
- **Dim When Inactive:** Optional, independent of floating. Choose 35%, 50%, 65%, 80%, or 90% inactive opacity; refocusing restores full opacity.
- **Normal Window Behavior:** One click disables floating and dimming, so other windows naturally cover it.
- **Sidebar:** Hidden by default using conservative, reversible DOM hooks. Turn off Hide Website Sidebar to restore the original inline styles. The site's own collapsed state may still need reopening using its sidebar button.
- **Menu bar:** The activity-wave icon brings the window back after closing it. Closing the window does not quit; use ⌘Q to quit.
- **Navigation:** ⌘1 returns to active tasks, ⌘R reloads, ⌘B opens the current page in your default browser.
- **Downloads:** Exported files use a native Save dialog. Links to outside sites open in your default browser.

## Login caveats

This is a genuine WebKit view, not a proxy or a password collector. Email/verification-code login is the recommended path if offered by Perplexity. Google or Apple may refuse authentication in an embedded browser; the app supports sign-in popups but cannot override identity-provider policy. Opening your browser does **not** transfer its login back into the app. If the site sends a verification link to your browser, return to the app and enter a code if available.

The authenticated Perplexity DOM is not bundled or controlled by this project. Sidebar suppression is best-effort, not a guaranteed API. It deliberately does not remove arbitrary navigation or guess at hashed class names. Login, actual task rendering, and current site-specific sidebar behavior must be checked on your account on first launch.

## Build

Requires macOS and Apple's Xcode Command Line Tools. There are no npm, Swift Package Manager, or third-party runtime dependencies.

```sh
bash scripts/build.sh
open "build/Active Task.app"
```

The script compiles optimized arm64 and x86_64 binaries, combines them into one universal executable, renders the original icon with AppKit, creates an ICNS, ad-hoc signs the bundle, verifies its signature, and creates a ZIP plus SHA-256 checksum.

## Test

```sh
node --test tests/sidebar.test.cjs
mkdir -p build
xcrun swiftc Sources/Behavior.swift tests/behavior.swift -o build/behavior-tests
build/behavior-tests
```

GitHub Actions additionally compiles both architectures, checks the bundle and icon, verifies the signature, and launches the application for a short process-liveness smoke test. That test is not authenticated UI acceptance.

## Privacy and implementation

Native AppKit window + `WKWebView`, using macOS's built-in WebKit. No app analytics, API keys, backend, local web server, page-content logging, or custom credential handling. Perplexity and its identity providers still handle your account under their own policies.

Sidebar JavaScript runs only on Perplexity's main frame in WebKit's isolated content world. There is no JavaScript-to-native command bridge. External top-level HTTP(S) links open in your browser; unknown custom schemes are not launched. WebKit's normal TLS and web security behavior remain enabled.

Preferences are stored under `com.paulfleury.activetask` in macOS UserDefaults. Authentication state lives in the default persistent WebKit website data store for this app.

## Manual acceptance checklist

- Sign in using your preferred login method, quit, reopen, and verify the session survives.
- Verify the actual active-task list is visible and responsive at compact and larger sizes.
- Confirm the sidebar is suppressed and the toggle restores navigation.
- Verify floating above another app, normal occlusion, inactive dimming, opacity levels, and full-opacity focus return.
- Check OAuth popup focus, Spaces/full-screen behavior, frame restoration, menu-bar reopen, external links, and a real file download.
- Verify Gatekeeper's first-launch experience on the intended Mac.

These checks require a real logged-in Mac. CI does not claim to complete them.
