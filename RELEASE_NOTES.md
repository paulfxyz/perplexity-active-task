# Active Task 2.1.0

Your active-session count, right beside the menu-bar icon.

## What's new

- **A live number:** Three pinned sessions plus one other active session display **4**. Counts are not hard-coded, and multiple digits fit naturally.
- **Independent refresh:** A background dashboard uses the app's existing login, even when the main window is closed or you are inside a task or Usage page.
- **Honest states:** Confirmed empty lists show **0**; loading, authentication, network, unsupported, or stale states show **…**, not a false zero.
- **Manual refresh:** Use **Refresh Task Count** in the menu-bar menu. The reader polls about every five seconds and revalidates the page about once a minute while the app is running.
- **Large-list limits:** Detected pagination or at least 50 loaded rows adds `+`; this is a DOM count, not an official backend task-total API.

The corrected **US$0.012 per credit** rate, all eleven opacity choices, login store, and verified in-app updater are unchanged.

## Update

From **2.0.0**, use **Active Task > Check for Updates…**, then approve **Download & Restart**. From 1.x, or for a first install, download `Active-Task-macOS-universal.zip`, quit the old app, unzip, and replace **Active Task.app** in Applications.

Universal Apple silicon/Intel build for macOS 13+. The community build remains ad-hoc signed, **not Apple-notarized**; it does not bypass Gatekeeper or request administrator access.

The counter reads the English active dashboard's known semantic structure. Website changes, login, network conditions, pagination/virtualization, and App Nap can affect its availability or freshness. See [task-count details](https://github.com/paulfxyz/perplexity-active-task/blob/main/docs/TASK_COUNT.md) and [validation notes](https://github.com/paulfxyz/perplexity-active-task/blob/main/docs/VALIDATION.md).
