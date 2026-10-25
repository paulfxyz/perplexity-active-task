# Active Task 1.1.0

Your AI work. Quietly in view.

## What's new

- **Cost equivalent** beneath Session usage, plus a USD equivalent beside available organization credits, using **US$600 net / 10,000 credits = US$0.06 per credit**.
- Live DOM updates preserve original counts, avoid duplicate additions, and never guess at unreadable or abbreviated credit values. Estimates are account-specific, not invoices.
- **⌘2** opens organization Usage; available-pool equivalents are distinct from money spent.
- Eleven inactive-opacity choices: **5%, 10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%, and 95%**. The low values really work; the old 25% floor is removed.
- A native **Window Settings** panel, accessible from the sliders menu or **⌘,**.
- Smooth migration from older opacity preferences, with a 60% fresh-install default and dimming still off by default.
- A public MIT repository with screenshots, original banner, badges, contribution guidance, and detailed privacy, security, installation, and validation notes.

## Download

Download `Active-Task-macOS-universal.zip`, unzip it, and move **Active Task.app** to Applications. This universal build supports Apple silicon and Intel on macOS 13+.

The community app is ad-hoc signed, **not Developer ID signed or Apple-notarized**. If macOS blocks opening, verify the download and use Privacy & Security > Open Anyway if offered. Do not disable Gatekeeper.

## Updating

Quit 1.0.0, replace the application, and reopen it. The bundle identifier is unchanged; the app continues using its local preferences and WebKit store. A previous 65% opacity becomes 60%, and 35% becomes 30%. There is no automatic updater.

## Scope and limits

Active Task is an independent native window onto the Perplexity website, not an official client or API integration. Login compatibility, sidebar hiding, and credit-label detection depend on the live website and identity-provider policies; authenticated acceptance is separate from CI. Documentation screenshots use synthetic tasks in an isolated development build.

See the [README](https://github.com/paulfxyz/perplexity-active-task#readme), [installation guide](https://github.com/paulfxyz/perplexity-active-task/blob/main/INSTALL.md), and [validation notes](https://github.com/paulfxyz/perplexity-active-task/blob/main/docs/VALIDATION.md).
