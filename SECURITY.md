# Security

Active Task is a community utility, not independently security-certified software. Release builds are ad-hoc signed and are not Developer ID signed or Apple-notarized.

## Design boundaries

The app uses macOS's normal WebKit TLS and web-security behavior. Sidebar and cost-display JavaScript are limited to Perplexity's main frame and run in an isolated content world, with no JavaScript-to-native command bridge.

Top-level internal navigation is restricted to Perplexity and the identity-provider domains listed in the source. Other HTTP(S) links and mail links open externally; unknown custom schemes are not launched. This is not a network firewall: embedded website resources and subframes still follow normal WebKit rules.

Login sessions are local to the app's WebKit data store. The application does not import credentials or cookies from another browser and does not attempt to defeat embedded-browser sign-in policies.

## Update trust model

The 2.0.0 updater reads the stable Releases endpoint for this repository and accepts only the exact expected ZIP path, a supported stable version, a bounded declared size, and a GitHub SHA-256 digest. HTTPS redirects are limited to explicit GitHub hosts; cookies and URL credentials are disabled.

Before replacement, the app checks the ZIP digest and size, rejects unsafe archive paths and symlinks, validates the bundle identity/version and universal architectures, and verifies code-signature integrity. The user must explicitly approve Download & Restart. No sudo, Gatekeeper changes, quarantine removal, or privileged helper is used.

An ad-hoc signature and a checksum from the same GitHub release do **not** establish an Apple-verified publisher or independently authenticated update feed. Security depends on this repository's GitHub account, GitHub's infrastructure, HTTPS, and the local app. The updater is not Sparkle, has no separately pinned signing key, and is not Apple-notarized.

The old app is retained and immediate swap/open-command failures trigger rollback. A successful `open` command is not a health check: later crashes, unsupported login, or website problems require manual recovery. See [Updates](docs/UPDATES.md).

## Report a vulnerability

Do not post sensitive details, session cookies, passwords, or exploitation steps in a public issue. Email [hello@paulfleury.com](mailto:hello@paulfleury.com) with a minimal description, the affected version, and a safe way to reproduce.

For ordinary UI bugs, use a public issue with synthetic or redacted screenshots. Maintainer capacity is limited; there is no guaranteed response time or security-support SLA.
