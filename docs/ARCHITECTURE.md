# Architecture

Active Task is one small AppKit application with a WKWebView. It has no third-party runtime dependencies, embedded HTTP server, Electron runtime, account API integration, or project backend. jsdom is a development-only dependency for DOM integration tests.

## Source map

| Path | Responsibility |
| --- | --- |
| `Sources/App.swift` | App lifecycle, native window/menu/settings, WebKit navigation, popup and download delegates |
| `Sources/Behavior.swift` | Pure opacity calculation, supported levels, legacy-preference normalization |
| `Sources/Sidebar.js` | Main-frame-only, isolated-world, reversible sidebar suppression |
| `Sources/Cost.js` | Strict credit parsing and the disclosed net-rate calculation |
| `Sources/CostDisplay.js` | Route-scoped live session and organization cost additions |
| `Sources/UpdateCore.swift` | Strict version/release policy, SHA-256, archive and bundle validation |
| `Sources/UpdateHTTP.swift` | Bounded ephemeral downloads with explicit redirect allowlist |
| `Sources/UpdateController.swift` | Native update UI, optional checks, preparation, and restart approval |
| `scripts/install-update.sh` | Unprivileged swap/reopen, backup, and immediate-failure rollback |
| `Resources/Info.plist` | Stable bundle identity, release version, macOS minimum |
| `scripts/icon.swift` | Original vector artwork rendered using AppKit |
| `scripts/build.sh` | Dual-architecture compilation, icon generation, signing, ZIP, checksum |
| `tests/` | Sidebar and window behavior checks, synthetic documentation fixture |

## Window state

The main window starts at 520 × 700 with a 360 × 360 minimum. AppKit frame autosave remembers placement and size. Floating uses `NSWindow.Level.floating`; normal behavior uses `.normal`.

Focus changes update native `NSWindow.alphaValue` with a short animation. The window is fully opaque when focused, dimming is off, or a sign-in popup is open. Otherwise, opacity follows the selected inactive value. Settings are a separate native window, so opening them can dim the task window.

Supported inactive percentages are centralized in `WindowBehavior`. Existing preferences normalize once at launch to the nearest supported option; exact-distance ties choose the lower option.

## Web and authentication

The release uses the app's persistent default WebKit store. Perplexity owns the sign-in page; the app neither captures credentials through a custom form nor imports another browser's cookies.

Sign-in popups share WebKit's supplied configuration. There is no custom OAuth-token interception, provider-policy modification, or external-browser cookie transfer.

Sidebar code only changes known sidebar elements that do not contain the main content. It records previous inline styles and restores them when disabled, watches SPA child-list changes, and falls back to explicit collapse controls. It intentionally avoids broad `<nav>` suppression.

Cost code reads only the exact session-usage anchor and supported available-organization-credit labels on their corresponding routes. It uses idempotent DOM writes, scoped mutation handling, and separate mount maps for used credits and available credits. It does not fetch account data or change original credit text; see [Cost equivalent](COST_EQUIVALENT.md).

## Documentation isolation

`SCREENSHOT_BUILD` conditionally compiles the capture harness. That build uses a separate preferences suite and nonpersistent WebKit store and loads a bundled synthetic task fixture.

The release build omits the fixture resource and screenshot-only branches. CI checks that the fixture is absent from the shipping bundle. See [Screenshots](SCREENSHOTS.md).

## Updates

The updater is native and separate from WebKit. It never shares Perplexity cookies or account content with its GitHub client. Checks are optional; replacement requires explicit confirmation, a newer stable version, trusted transport, matching size/hash, and a validated bundle.

The current helper is copied to a private sibling stage before the app quits. It waits for the old process, retains the old bundle, swaps in the verified candidate, and reopens it. See [Updates](UPDATES.md) for the trust model and recovery limits.
