# Active-task menu-bar count

Active Task 2.1.0 displays a compact number immediately beside the activity icon. It follows the website's **Status: Active** session dashboard, counting pinned and ordinary active sessions together rather than counting sidebar links or only the Today group.

## Reading and refresh

A dedicated WebKit view opens the canonical active dashboard at `https://www.perplexity.ai/computer/tasks?status=active`. It shares the main app's persistent website store and process pool, so no new account, API key, browser-cookie import, or separate sign-in is introduced.

The native app polls a small DOM reader about every five seconds and revalidates that dashboard about once a minute. It also refreshes after relevant main-page navigation and offers **Refresh Task Count** in the menu-bar menu. The main window can be closed, minimized, or showing a different page without changing which dashboard is counted.

The background view may expand recognized collapsed date/pinned groups, only within that view. It never selects, edits, starts, archives, pins, or deletes a session, and never changes the visible window's group state through a click.

## What qualifies

The reader requires the expected root/www origin and active-list URL, the English Session dashboard tab, the **Status: Active** control, and an unselected **Project** control. It counts real session rows in role-based tables using their selection-checkbox semantics, not generic row totals.

- **Pinned and other groups:** Combined into one count.
- **Sidebar, navigation, menus and dialogs:** Excluded.
- **Loading/footer placeholders:** Excluded unless the page is explicitly loading, in which case no exact result is supplied.
- **Hidden clones:** Excluded, while a real session's hover-only selection checkbox may remain hidden.
- **Duplicate identifiers:** Deduplicated when an explicit session ID or session link is available. Identical titles alone are not treated as duplicates.
- **Changing filters, collapsed groups, or unsupported markup:** Not accepted as a trustworthy global count.

The reader does not fetch account APIs, inspect internal React stores, or return session titles/contents to native code. It returns only a versioned count/status/pagination object through isolated-world JavaScript evaluation; there is no page-callable native command handler.

## Display states

| Display | Meaning |
| --- | --- |
| `4` | Four loaded active sessions on the recognized small dashboard |
| `12` | Twelve; the native status item expands rather than truncating digits |
| `0` | A recognized, loaded empty active dashboard |
| `…` | Unknown, loading, sign-in required, offline, unsupported, or too stale |
| `N+` | At least N loaded sessions when pagination is detected, a declared row count is larger, or the loaded list reaches 50 |

During an ordinary reload, the last good count can remain visible for up to 90 seconds with a refreshing tooltip. Explicit failure/unsupported states clear it; the app does not persist counts across launches or present a missing reading as zero.

## Limits

This is a website companion, not an official task-total endpoint. It depends on the current English dashboard structure, successful authentication, normal page loading, and OS scheduling. App Nap, sleep, network errors, or provider changes may defer updates.

Pagination and virtualization can limit which rows are available in the DOM. Known pagination indicators and lists of at least 50 loaded sessions are labelled as lower bounds, but this cannot establish an authoritative total for every future dashboard layout. Compare the website when an exact large-list total matters.

The background page consumes normal WebKit/network resources and loads Perplexity's own resources under its policies. No counter history or session names are logged or exported by the feature.

## Verification

DOM tests cover a four-session fixture with three pinned plus one ordinary row, live changes, multi-digit values, duplicates, navigation/menu exclusion, hover controls, empty/loading/auth/offline states, filters, and pagination markers. Native tests reject malformed count messages and verify number, zero, lower-bound, and stale/unknown presentations.

The documentation build runs the actual counter against a synthetic page in an unattached background WKWebView. It must deliver **4** through native polling into the real NSStatusBar button before a control snapshot is saved. That validates the background WebKit/native path without exposing or logging an account's task list.
