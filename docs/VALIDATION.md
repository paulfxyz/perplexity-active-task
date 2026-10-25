# Validation

Active Task distinguishes source-level checks, hosted macOS tests, documentation captures, and real-account acceptance. None should be substituted for the others.

## Automated release checks

The [GitHub Actions workflow](https://github.com/paulfxyz/perplexity-active-task/actions/workflows/build.yml) runs:

- **Sidebar behavior:** Ten tests for domain guards, reversible hiding, main-content protection, grid repair, explicit-collapse fallback, SPA mutations, idempotency, and disabled initialization.
- **Window behavior:** Twenty-four assertions covering focus/dimming, all eleven requested opacity levels, clamping, legacy-value migration, and nonfinite-value handling.
- **Cost conversion:** Exact net-rate math, grouping and decimal formats, rounding, subcent amounts, invalid values, and refusal of compact counts.
- **Cost DOM integration:** Real DOM fixtures cover session and organization additions, text updates, subtree replacement, SPA routing, collapse/reopen, duplicate prevention, allowed origins, and unreadable-value recovery.
- **Universal compilation:** Optimized arm64 and x86_64 executables, combined and architecture-checked.
- **Bundle checks:** Plist validation, generated icon presence, ad-hoc signature verification, and absence of the screenshot fixture from the shipping app.
- **Launch smoke test:** Starts the native executable and verifies it remains alive for twelve seconds. This checks liveness, not UI correctness or login.
- **Documentation capture:** A separately compiled native build renders synthetic tasks and captures its own overview, settings panel, session-cost row, and organization-cost suffix. The actual WebKit-injected values must equal `US$13.13` and `(US$600.00)` before capture succeeds.
- **Release integrity:** The tag must match the bundle version, and the ZIP must match its SHA-256 checksum before publication.

For the result of a particular version, inspect that tag's workflow run rather than assuming a green badge proves every platform interaction.

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
- Open a real session's Usage panel; confirm that Cost equivalent follows readable credits used at US$0.06 per credit.
- Use ⌘2 to open organization Usage; verify that the suffix refers only to the available pool, not monthly spend, refill, or grant history.

Hosted CI and synthetic screenshots do not establish these account-specific and device-specific outcomes. The public release is not Apple-notarized and does not claim an independent security audit.
