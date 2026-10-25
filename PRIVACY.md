# Privacy

Active Task is a native window around Perplexity's website, with local USD equivalents for displayed credits. There is no project-operated backend, analytics SDK, telemetry integration, remote balance collector, or task-content export service in this app.

## What stays on your Mac

- **Preferences:** Window frame, zoom, floating, sidebar, dimming, and inactive-opacity choices use macOS UserDefaults under `com.paulfleury.activetask`.
- **Website session:** Perplexity cookies, website storage, and other browser-managed data use this application's persistent default WKWebView data store.
- **Downloads:** Files are saved to the location you choose in the native Save dialog.
- **Updater data:** Confirmed updates use temporary downloads and a private staging folder beside the app. Previous bundles and a local installation log are retained for recovery; they do not contain copied WebKit session data.

The app does not import Safari or Comet cookies, request API keys, log page contents, or implement its own password collection. The local website store can contain sensitive account data; “local” does not mean separately encrypted by this application.

Cost-display scripts read the visible session-credit or organization-credit text, calculate its equivalent at the disclosed rate, and add it to the same page. The scripts do not store those readings, intercept account APIs, send network requests, or build usage history.

## What goes over the network

The embedded website contacts Perplexity, identity providers, and resources they include. Their handling of your account, task data, and website telemetry is controlled by those services, not by this project.

External links open in your default browser. Starting in 2.0.0, the app itself can contact GitHub's public Releases API to check for updates. Optional automatic checks run after launch and every six hours, and can be turned off in Settings.

Only a confirmed update downloads a release archive from GitHub's release infrastructure. The updater uses a separate ephemeral client with cookies, URL credentials, and cache disabled; it sends a generic updater User-Agent, not Perplexity cookies, task content, usage readings, or account data. GitHub still sees normal network metadata such as the request and IP address.

## Public repository assets

Documentation screenshots contain synthetic task examples, not real account content. The screenshot build uses an ephemeral WebKit store and a separate preferences suite; its fixture and capture commands are absent from the production build.

Do not include cookies, verification codes, private task titles, account details, or browser-storage files in a public bug report. See [Security](SECURITY.md) if you discover a vulnerability.
