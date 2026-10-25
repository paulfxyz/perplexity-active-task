# Cost equivalent

Active Task 2.0.0 adds local USD context without replacing the website's credit values. The design is inspired by [Perplexity Cost Transparency](https://github.com/paulfxyz/pplx-cost-transparency), with the corrected purchase packs explicitly supplied by the user.

## The math

The clarified net packs are **10,000 credits for US$120**, **50,000 for US$600**, and **100,000 for US$1,200**. They all produce the same rate.

```text
US dollars per credit = 120 / 10,000 = 600 / 50,000 = 1,200 / 100,000 = 0.012
Cost equivalent = displayed credits × 0.012
```

| Displayed credits | Equivalent |
| ---: | ---: |
| 1 | US$0.01 |
| 100 | US$1.20 |
| 218.77 | US$2.63 |
| 1,000 | US$12.00 |
| 10,000 | US$120.00 |
| 11,688.38 | US$140.26 |
| 11,717.13 | US$140.61 |
| 50,000 | US$600.00 |
| 100,000 | US$1,200.00 |

Amounts use two decimal places in USD. A positive result below one cent shows `<US$0.01` rather than implying it is free.

Version 1.1.0 used the earlier US$0.06 assumption and therefore overstated equivalents fivefold under the corrected packs. It did not modify or charge additional credits. Version 2.0.0 fixes both session and organization equivalents; regression tests cover all three packs and the reported readings.

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

The rate is fixed in this release's `Sources/Cost.js`; the hover disclosure derives from the same constants instead of maintaining a separate numeric rate. Users with a different purchase rate must edit those constants and rebuild; the app does not claim that US$0.012 is universal.

## Privacy and provenance

The conversion runs locally in the main frame's isolated WebKit world. It does not read cookies, intercept APIs, save readings, collect history, or add network requests.

The strict numeric parser and semantic approach are adapted from the author's MIT-licensed [reference project](https://github.com/paulfxyz/pplx-cost-transparency). The native app uses its own namespaced DOM markers and the corrected net rate, with automated unit/DOM tests and separately labelled fixture screenshots.
