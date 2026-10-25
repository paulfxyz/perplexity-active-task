# Security

Active Task is a community utility, not independently security-certified software. Release builds are ad-hoc signed and are not Developer ID signed or Apple-notarized.

## Design boundaries

The app uses macOS's normal WebKit TLS and web-security behavior. Sidebar JavaScript is limited to Perplexity's main frame and runs in an isolated content world, with no JavaScript-to-native command bridge.

Top-level internal navigation is restricted to Perplexity and the identity-provider domains listed in the source. Other HTTP(S) links and mail links open externally; unknown custom schemes are not launched. This is not a network firewall: embedded website resources and subframes still follow normal WebKit rules.

Login sessions are local to the app's WebKit data store. The application does not import credentials or cookies from another browser and does not attempt to defeat embedded-browser sign-in policies.

## Report a vulnerability

Do not post sensitive details, session cookies, passwords, or exploitation steps in a public issue. Email [hello@paulfleury.com](mailto:hello@paulfleury.com) with a minimal description, the affected version, and a safe way to reproduce.

For ordinary UI bugs, use a public issue with synthetic or redacted screenshots. Maintainer capacity is limited; there is no guaranteed response time or security-support SLA.
