# Proposal: Scope down eager parsing

## Why

Chrono's casual parsers currently match far more than its primary consumer (space-nli, a task-input parser) can meaningfully use, and several patterns are outright buggy. Empirically verified against the current build (reference date 2026-07-16 10:30):

- `now` parses as a full datetime — useless for task scheduling.
- Second-granularity expressions parse (`in 30 seconds`, `30 seconds ago`) — below the useful resolution for scheduling.
- Explicit past expressions parse and survive `forwardDate: true` (`2 minutes ago` → 10:28 today), so they end up scheduling tasks "today" in space-nli despite its past-date guard being day-granular.
- The time-expression parser accepts a bare whitespace or comma as its "connector", so **any standalone number** parses as a time: `buy 2 apples` → 2am, `read chapter 12` → hour 12.
- Hour values are not range-checked and overflow via the calendar: `test at 27` → tomorrow 03:00, `test at50`/`pay 50` → +2 days 02:00, `test at 99` → +4 days.
- The connector can match inside a word: `version 2.0` → matches `on 2` as a time.
- `test at 3` yields an hour-only, meridiem-implied fragment that space-nli misclassifies as date-bearing → a date pill for "today" with no time.
- `for 2 hours` parses as *now + 2h* (the within-parser matches `for`), colliding with space-nli's own DurationScanner which already handles durations (`2 hours`, `30m`, `2u`, `2 Stunden`, …) in all locales.

The same pattern families exist in all seven locales (EN, ES, FR, DE, NL, PT, JA); a locale-by-locale audit (subagent pressure-test + empirical harness runs) feeds the per-locale deltas in `design.md`.

## What Changes

**Chrono (this repo) — remove/tighten, all locales:**

- **BREAKING** Remove `now`-equivalents from the casual date parsers (EN `now`; ES `ahora`; FR `maintenant`; DE `jetzt`; NL `nu`; PT `agora`; JA equivalent per audit).
- **BREAKING** Remove second-granularity units from every relative time-unit pattern (ago/later/within/casual-relative) in all locales. Explicit ISO-8601 timestamps keep their seconds.
- **BREAKING** Remove duration-style prefixes from the "within" parser family so bare durations no longer parse as deadlines (EN `for`; locale equivalents such as NL `voor`, DE `für`, FR `pendant/pour`, ES/PT `durante/por` per audit). `in`/`within` (and equivalents) stay.
- **BREAKING** Tighten numeric time expressions in every locale:
  - A real connector word (`at`, `from`, `after`, `before`, locale equivalents) or string start is required — bare whitespace/comma no longer qualifies, so standalone numbers stop matching as times.
  - Connector must sit on a word boundary (no more `versi[on 2].0`) and be followed by whitespace (no more `at50`).
  - Hours must be 0–23 and minutes 0–59; out-of-range values reject the match instead of overflowing into later days.
  - Bare hours (no minutes/meridiem) still produce an hour-only result after an explicit connector so date+time merging (`tomorrow at 3`) keeps working; consumers decide whether a standalone ambiguous hour is usable.
- Past-direction parsers (`yesterday`, `… ago`, `last week`, …) **stay in Chrono** — forward-only is a consumer policy, not a library property.
- Cleanup: stray debug `print` in `ENSimpleTimeParser`.

**space-nli (~/code/space-nli) — consumer-side forward-only policy:**

- Only results with *known* date components may set a schedule; an hour-only fragment (`test at 3`) must be ignored entirely — no date, no time.
- Extend the existing `applyPastDates: false` guard from day-granularity to instant-granularity for results with known date+time, so `2 minutes ago`, `30 seconds ago`, `yesterday at 3pm` are dropped rather than scheduled "today".

## Capabilities

### New Capabilities

- `casual-parsing-scope`: what Chrono's casual configurations must and must not recognize — exclusion of "now", second-granularity relative expressions, and duration phrases; retention of past-direction parsing as library capability.
- `numeric-time-validation`: validity rules for numeric time expressions across all locales — connector requirements, word boundaries, and hour/minute range checks.
- `forward-only-consumption` (space-nli, cross-repo): how a forward-only consumer applies Chrono results — date-bearing classification and instant-granularity past filtering.

### Modified Capabilities

_None — no specs exist yet in this repo._

## Impact

- **Chrono**: casual/strict configurations of all 7 locales (`Sources/Chrono/Locales/*/Parsers/*`), primarily the casual-date, time-expression, and time-unit parser families. Existing tests asserting `now`/seconds/`for`-duration/overflow behavior must be updated.
- **space-nli**: `Sources/SpaceNLI/Engine/TaskInputParser.swift` (date-bearing filter, past guard) and `DateClassifier.swift`; its tests. Cross-repo tasks are marked explicitly in `tasks.md`.
- **Consumers**: any consumer relying on `now`, seconds, `for`-durations, or bare-number time matches will see fewer results (intended). space-nli's `DurationScanner` picks up duration phrases that Chrono stops matching.
