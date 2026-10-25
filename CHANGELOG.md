# Changelog

## 1.1.0 · 2026-10-25

- Added a live **Cost equivalent** row under Session usage and an inline equivalent beside available organization credits.
- Use the newly specified **US$600 net / 10,000 credits = US$0.06 per credit** assumption; this is not the older browser extension's rate.
- Added **View → Organization Usage** and ⌘2, with explicit available-pool versus credits-used semantics.
- Added pure conversion and jsdom integration tests for live updates, remounts, navigation, invalid readings, and duplicate prevention.
- Expanded inactive opacity to exactly **5%, 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%, and 95%**.
- Removed the old 25% opacity floor so 5%, 10%, and 20% actually render at those levels.
- Added a native settings window with ⌘, and immediate controls for floating, dimming, sidebar visibility, and opacity.
- Added deterministic migration of old opacity values to the nearest supported option; ties choose the lower value.
- Changed the fresh-install inactive-opacity preference to 60%; inactive dimming remains off by default.
- Read the About version from the bundle metadata instead of a hard-coded version string.
- Prepared the public MIT repository with original banner artwork, fixture screenshots, badges, developer docs, installation help, privacy/security policies, contribution guidance, and issue templates.
- Added an isolated documentation build for repeatable native window, settings, session-cost, and organization-cost screenshots without account data.
- Added pull-request CI and limited release-write permissions to the release job.

## 1.0.0 · 2026-10-25

- Initial compact native macOS wrapper for Perplexity Computer active tasks.
- Persistent WebKit session, always-on-top, inactive dimming, normal window mode, and best-effort reversible sidebar suppression.
- Native toolbar, menu-bar restore, zoom, sign-in popups, file saving, and original activity/AI app icon.
- Universal Apple silicon and Intel build for macOS 13+, with ad-hoc signing and GitHub release automation.
