# Active Task 2.0.0

Correct credit math, plus confirmed in-app updates.

## Corrected cost equivalents

The clarified packs are **10,000 credits for US$120**, **50,000 for US$600**, and **100,000 for US$1,200**. All mean **US$0.012 per credit**.

Version 1.1.0 used US$0.06 and overstated the equivalent fivefold under those packs. Version 2.0.0 fixes both Session usage and available organization credits, derives the hover rate from the calculator constants, and adds regression tests for all packs and reported readings.

- 11,688.38 credits → **US$140.26**
- 11,717.13 credits → **US$140.61**
- 50,000 credits → **US$600.00**

This changes only the displayed estimate. Original Perplexity credit values and billing are untouched.

## In-app updates

- **Check for Updates…** in the application menu, menu-bar menu, sliders menu, and Settings.
- Current version/status in Settings, with optional launch and six-hour automatic checks.
- Explicit **Download & Restart** confirmation; no silent installation.
- Trusted GitHub redirects, bounded downloads, SHA-256 and size checks, archive checks, bundle/version/architecture validation, and code-signature integrity verification.
- Unprivileged in-place replacement and reopen, previous-app backup, and rollback on immediate replacement/open-command failures.

See [the full update process and trust limits](https://github.com/paulfxyz/perplexity-active-task/blob/main/docs/UPDATES.md).

## Install this release

**From 1.x, install 2.0.0 manually once.** Quit the old app, download and unzip `Active-Task-macOS-universal.zip`, replace the app in Applications, and reopen. The bundle identifier is unchanged; the application continues using its local preferences and WebKit store.

The universal app supports macOS 13+ on Apple silicon and Intel. It remains ad-hoc signed, **not Apple-notarized**; macOS or managed-device policies may require approval or prevent installation. The updater does not bypass Gatekeeper or request administrator access.

Live login and DOM-label acceptance remain separate from automated native tests and synthetic screenshots. Estimates use the stated net rate, not a live billing API or invoice.
