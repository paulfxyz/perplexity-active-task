# Documentation screenshots

Repository images must not expose real tasks, account information, sign-in sessions, or verification codes. The screenshots here are reproducible captures of the native UI using a labelled synthetic task fixture.

## What the images represent

- **Overview:** The running AppKit window, toolbar, and a WKWebView rendering `tests/fixtures/ScreenshotFixture.html`. The sample list is not a capture or pixel-accurate reproduction of the live Perplexity task interface.
- **Settings:** The actual native settings panel used by the production app, captured through AppKit.
- **Banner:** Original vector illustration in `.github/img/banner.svg`, not a screenshot.

To avoid requiring Screen Recording permission on CI, the harness snapshots the native window frame and composites an actual `WKWebView.takeSnapshot` image into its corresponding content rectangle. It is a documentation capture, not evidence that sign-in or live task rendering passed.

## Reproduce on a Mac

From the repository root:

```sh
SCREENSHOT_BUILD=1 BUILD_DIR="$PWD/build/documentation" bash scripts/build.sh
"build/documentation/Active Task.app/Contents/MacOS/ActiveTask" \
  --screenshots "$PWD/build/screenshots"
```

The app writes `screenshot-overview.png` and `screenshot-settings.png`, then exits. Review both before copying them into `docs/`.

This build uses an ephemeral WebKit store and a separate UserDefaults suite. The regular build has no screenshot mode and does not include the fixture resource; never distribute the documentation build as the release app.
