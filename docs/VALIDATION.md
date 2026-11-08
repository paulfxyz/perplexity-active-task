# Validation

Active Task distinguishes source-level checks, hosted macOS tests, documentation captures, and real-account acceptance. None should be substituted for the others.

## Automated release checks

The [GitHub Actions workflow](https://github.com/paulfxyz/perplexity-active-task/actions/workflows/build.yml) runs:

- **Sidebar behavior:** Ten tests for domain guards, reversible hiding, main-content protection, grid repair, explicit-collapse fallback, SPA mutations, idempotency, and disabled initialization.
- **Window behavior:** Twenty-four assertions covering focus/dimming, all eleven requested opacity levels, clamping, legacy-value migration, and nonfinite-value handling.
- **Cost conversion:** Exact net-rate math, grouping and decimal formats, rounding, subcent amounts, invalid values, and refusal of compact counts.
- **Corrected packs:** All three purchase packs imply US$0.012 per credit; regression inputs 11,688.38 and 11,717.13 produce US$140.26 and US$140.61.
- **Cost DOM integration:** Real DOM fixtures cover session and organization additions, text updates, subtree replacement, SPA routing, collapse/reopen, duplicate prevention, allowed origins, and unreadable-value recovery.
- **Count DOM integration:** Pinned-plus-ordinary totals, changing and multi-digit counts, hover checkboxes, navigation/menu exclusion, duplicate IDs, empty/loading/auth/offline states, filters and pagination lower bounds.
- **Native count state:** Strict numeric/version/boolean decoding, digit presentation, genuine zero, lower-bound labels, unknown and stale cutoffs.
- **Universal compilation:** Optimized arm64 and x86_64 executables, combined and architecture-checked.
- **Bundle checks:** Plist validation, generated icon presence, ad-hoc signature verification, and absence of the screenshot fixture from the shipping app.
- **Launch smoke test:** Starts the native executable and verifies it remains alive for twelve seconds. This checks liveness, not UI correctness or login.
- **Documentation capture:** A separately compiled native build renders synthetic tasks and captures its own overview, settings panel, session-cost row, and organization-cost suffix. The actual WebKit-injected values must equal `US$2.63` and `(US$120.00)` before capture succeeds.
- **Native updater:** Semantic versions, URL/metadata/size/checksum/OS policy, archive-name and actual ZIP-symlink rejection, real signed universal fixture replacement/reopen, late-preflight protection, backup retention, and fault-injected immediate-launch rollback.
- **Live update probe:** Native public GitHub feed request, allowlisted redirects, actual ZIP size/hash verification, with no installation. An external HTTP 403 is recorded as a warning rather than blocking otherwise valid builds; other probe failures still fail CI.
- **Native background counter:** The actual hidden WKWebView must read a four-session fixture and update the actual NSStatusBar button to `4` before an AppKit preview is rendered from its native properties. This is not a WindowServer/system-menu-bar screenshot.
- **Release integrity:** The tag must match the bundle version, and the ZIP must match its SHA-256 checksum before publication.

For the result of a particular version, inspect that tag's workflow run rather than assuming a green badge proves every platform interaction.

The 2.1.0 source commit passed the full [main build](https://github.com/paulfxyz/perplexity-active-task/actions/runs/42511425951), including the live probe and background counter. Its tag runner's anonymous live probe returned HTTP 403 on two attempts. The release recovery workflow therefore verifies a successful build's exact tag commit, archive checksum and version, fills only an empty existing draft, checks uploaded asset digests, and publishes without replacing or rebuilding the verified app.

## Real-Mac acceptance checklist

- Sign in with your preferred account flow; quit, reopen, and check session retention.
- Confirm the real active-task list is usable at compact and larger sizes.
- Toggle sidebar hiding and confirm main content remains intact.
- Verify floating above ordinary windows, and normal occlusion when disabled.
- Try 5%, 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%, and 95%; focusing must always restore 100%.
- Verify settings changes, keyboard shortcuts, menu-bar restore, frame restoration, and zoom.
- Test sign-in popup focus, a real download, an external link, Spaces, and full-screen arrangements.
- Check Gatekeeper's first-launch experience on the intended Mac.
- Update from 1.0.0 and verify preferences and session retention.
- Open a real session's Usage panel; confirm that Cost equivalent follows readable credits used at US$0.012 per credit.
- Use ⌘2 to open organization Usage; verify that the suffix refers only to the available pool, not monthly spend, refill, or grant history.
- Install 2.0.0 manually from 1.x, then test Check for Updates, the automatic-check toggle, update availability/error UI, and a later real release's confirmed install on a writable Mac.
- In 2.1.0, compare the menu-bar number to pinned plus ordinary active sessions; verify a changing count, a completed/empty list, main-window close, task/Usage navigation, expired login and offline behavior.

Hosted CI and synthetic screenshots do not establish these account-specific and device-specific outcomes. The public release is not Apple-notarized and does not claim an independent security audit.
