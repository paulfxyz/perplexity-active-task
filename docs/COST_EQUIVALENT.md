# Cost equivalent

Active Task 1.1.0 adds local USD context without replacing the website's credit values. The design is inspired by [Perplexity Cost Transparency](https://github.com/paulfxyz/pplx-cost-transparency); the rate is the new explicit assumption requested for this app, not a copy of that extension's previous assumption.

## The math

The author's stated purchase rate is **US$600 net per 10,000 credits**.

```text
US dollars per credit = 600 / 10,000 = 0.06
Cost equivalent = displayed credits × 0.06
```

| Displayed credits | Equivalent |
| ---: | ---: |
| 1 | US$0.06 |
| 100 | US$6.00 |
| 218.77 | US$13.13 |
| 1,000 | US$60.00 |
| 10,000 | US$600.00 |
| 50,000 | US$3,000.00 |

Amounts use two decimal places in USD. A positive result below one cent shows `<US$0.01` rather than implying it is free.

## Two displays, different meanings

- **Session usage:** A row labelled **Cost equivalent** is inserted immediately below the recognized native Session usage row on `/computer/tasks/<session>`. It estimates the equivalent of credits used.
- **Organization Usage:** An inline `(US$…)` suffix is appended beside the supported Available org credits / organization credits / organisation credits labels on `/account/org/credits-usage`. It represents the remaining shared pool, not money spent or a cash balance.

Hover over either addition for the purchase assumption and qualification. View > Organization Usage or ⌘2 opens the organization page in the app; appropriate account access is still required.

## Detection and updates

The script targets the English `About session usage` information button and exact English organization labels. The known native semantic row is preferred, with a bounded fallback; it never guesses from a whole card or page total.

Explicit plain, comma-grouped, apostrophe-grouped, and space-grouped counts are supported, including recognized decimal conventions. Abbreviations such as `10k`, negative values, arbitrary units, ranges, malformed groupings, and unsafe integer magnitudes are refused.

Session readings that cannot be parsed show `Unavailable`. Organization loading placeholders show `(Unavailable)`; unsupported organization formats hide the suffix until a readable value returns. Neither is assumed to be zero.

Mutation observers follow mounted panels, text changes, subtree replacement, and SPA navigation. App-owned writes are idempotent and excluded from further extraction, so the dollar suffix cannot be parsed back as credits or duplicated by repeated script initialization.

## What it does not tell you

This is an **account-specific net-rate equivalent**, not an official price feed, invoice, tax calculation, refund value, cost prediction, spending cap, or billing reconciliation.

It is only as fresh and precise as the displayed count. Taxes, discounts, grants, subscriptions, included credits, exchange rates, differently priced purchases, and reporting delays are not modeled.

The rate is fixed in this release's `Sources/Cost.js`. Users with a different purchase rate must edit those explicit constants and rebuild; the app does not claim that US$0.06 is universal.

## Privacy and provenance

The conversion runs locally in the main frame's isolated WebKit world. It does not read cookies, intercept APIs, save readings, collect history, or add network requests.

The strict numeric parser and semantic approach are adapted from the author's MIT-licensed [reference project](https://github.com/paulfxyz/pplx-cost-transparency). The native app uses its own namespaced DOM markers and the newly specified net rate, with automated unit/DOM tests and separately labelled fixture screenshots.
