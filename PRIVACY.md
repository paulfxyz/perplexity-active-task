# Privacy

Active Task is a native window around Perplexity's website, with local USD equivalents for displayed credits. There is no project-operated backend, analytics SDK, telemetry integration, remote balance collector, or task-content export service in this app.

## What stays on your Mac

- **Preferences:** Window frame, zoom, floating, sidebar, dimming, and inactive-opacity choices use macOS UserDefaults under `com.paulfleury.activetask`.
- **Website session:** Perplexity cookies, website storage, and other browser-managed data use this application's persistent default WKWebView data store.
- **Downloads:** Files are saved to the location you choose in the native Save dialog.

The app does not import Safari or Comet cookies, request API keys, log page contents, or implement its own password collection. The local website store can contain sensitive account data; “local” does not mean separately encrypted by this application.

Cost-display scripts read the visible session-credit or organization-credit text, calculate its equivalent at the disclosed rate, and add it to the same page. The scripts do not store those readings, intercept account APIs, send network requests, or build usage history.

## What goes over the network

The embedded website contacts Perplexity, identity providers, and resources they include. Their handling of your account, task data, and website telemetry is controlled by those services, not by this project.

External links open in your default browser. The app has no automatic updater or background GitHub-check mechanism; downloading updates or opening repository links contacts GitHub through your browser.

## Public repository assets

Documentation screenshots contain synthetic task examples, not real account content. The screenshot build uses an ephemeral WebKit store and a separate preferences suite; its fixture and capture commands are absent from the production build.

Do not include cookies, verification codes, private task titles, account details, or browser-storage files in a public bug report. See [Security](SECURITY.md) if you discover a vulnerability.
