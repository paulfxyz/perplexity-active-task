# Documentation screenshots

Repository images must not expose real tasks, account information, sign-in sessions, or verification codes. The screenshots here are reproducible captures of the native UI using a labelled synthetic task fixture.

## What the images represent

- **Overview:** The running AppKit window, toolbar, and a WKWebView rendering `tests/fixtures/ScreenshotFixture.html`. The sample list is not a capture or pixel-accurate reproduction of the live Perplexity task interface.
- **Settings:** The actual native settings panel used by the production app, captured through AppKit.
- **Session cost:** A synthetic Session usage row with 218.77 credits; the actual injected script adds `Cost equivalent` and `US$2.63`.
- **Organization cost:** A synthetic Available org credits card with 10,000 credits; the actual injected script adds `(US$120.00)` and ignores unrelated spend totals.
- **Banner:** Original vector illustration in `.github/img/banner.svg`, rendered to `.github/img/banner.png` for consistent README display. It is not a screenshot.

To avoid requiring Screen Recording permission on CI, the harness snapshots the native window frame and composites an actual `WKWebView.takeSnapshot` image into its corresponding content rectangle. It is a documentation capture, not evidence that sign-in or live task rendering passed.

## Reproduce on a Mac

From the repository root:

```sh
SCREENSHOT_BUILD=1 BUILD_DIR="$PWD/build/documentation" bash scripts/build.sh
"build/documentation/Active Task.app/Contents/MacOS/ActiveTask" \
  --screenshots "$PWD/build/screenshots"
```

The app writes `screenshot-overview.png`, `screenshot-settings.png`, `screenshot-session-cost.png`, and `screenshot-organization-cost.png`, then exits. Review all four before copying them into `docs/`.

This build uses an ephemeral WebKit store and a separate UserDefaults suite, and does not start automatic network update checks. For local fixtures only, the capture harness passes a synthetic location into the same cost-display module inside the isolated content world. The regular build has no capture harness and does not include the fixture resource; never distribute the documentation build as the release app.
