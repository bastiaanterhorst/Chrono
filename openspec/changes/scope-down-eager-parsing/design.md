# Design: Scope down eager parsing

## Context

Chrono.swift (a Swift port of chrono JS) feeds space-nli, the task-input parser of a task app. A full pressure-test of all 7 locales (one audit per locale + one for the shared/common parsers, each empirically verified with a harness against reference date 2026-07-16 10:30) found four cross-locale bug families plus several locale-specific ones:

| Family | EN | ES | FR | DE | NL | PT | JA |
|---|---|---|---|---|---|---|---|
| "now" keyword parses | `now` | `ahora` | `maintenant` | `jetzt` | `nu` | `agora` | — (safe) |
| Seconds-granularity units | 5 parsers (incl. `+30s`) | within-parser | — (safe) | 3 parsers (incl. `s`) | 2 parsers | — (safe) | — (safe) |
| Bare number → hour | yes (`\s`/`,` connector) | yes | no (needs `h`/`:`) | yes | no (needs `uur`/`:`) | yes (prefix optional) | no (needs `時`) |
| Hour/minute overflow into later days | 0–99 | 0–99 | 0–99 + min 0–99 | ≤24 only | ≤24 only | 0–99, eats `20[24]` | 0–99 + min 0–99, eats `1[00時]` |
| Duration phrase → point in time | `for 2 hours` | — (but bare-number bug fires) | — (safe) | `während/etwa 2 Stunden`, bare `3 Wochen` | `2 uur` always clock time | — (but bare-number bug fires) | `2時間` → 02:00 (時 inside 時間) |
| Keyword matches inside words | `versi[on] 2` | — | `comman[de] 3h`, `[l]endemain`, `soir[ée]`, `après-[midi]` | `Feier[abend]` | — | `it[em] 2 dias`, `apan[ha] 2 dias` | `[朝]ごはん`, `深[夜]` |

Structural findings that amplify everything: `AbstractParserWithWordBoundaryChecking` is a no-op (adds no boundaries despite the name), and `ForwardDateRefiner` under `forwardDate: true` never rescues past results (it only bumps year-uncertain dates 1–3 days in the past by one year, and never touches time-only or explicit-past results). Also stray debug `print()`s in `ENSimpleTimeParser` and `JATimeExpressionParser`.

Settled prior decisions that constrain this change:
- Commit `126dc1c` deliberately keeps short weekday/month abbreviation vocabulary parsing standalone (EN `sun`/`sat`, ES `mar`, FR `mer`/`jeu`, NL `zo`/`vrij`/`zat`, PT `ter`/`mar`) — only DE keeps its removals. Homograph findings from the audit (`may`, `sept jours`, `dez pessoas`, `bel Jan`, …) are therefore **out of scope**.
- Commit `7c3b13b` deliberately parses dotted numerics as dates (all locales). The audit shows this eats decimals/versions (`1.5 dollars` → Jan 5, `versão 2.5` → May 2, `Python 3.11` → Nov 3) — kept as an open question, not silently changed here.

## Goals / Non-Goals

**Goals:**
- Remove "now", seconds-granularity, and duration-phrase parsing from all casual configurations.
- Make numeric time expressions well-formed: real connectors, word/digit boundaries, hour/minute range checks (per-locale ranges).
- Ensure an ambiguous standalone `at 3` leads to *nothing* being applied in space-nli (no date pill, no time).
- Enforce forward-only recognition in space-nli (consumer), including sub-day past instants (`2 minutes ago`).

**Non-Goals:**
- Removing past-direction parsers from Chrono (kept for library flexibility; consumer filters).
- Revisiting weekday/month abbreviation vocabulary (settled by `126dc1c`).
- Changing dotted-numeric date behavior (settled recently by `7c3b13b`; flagged as open question).
- ISO-8601/strict-format parsing (keeps seconds, unchanged).
- Adding missing coverage (e.g. JA has no minute/hour relative parser; that gap stays).

## Decisions

**D1 — Forward-only lives in space-nli, not Chrono.** Chrono keeps parsing `yesterday`/`ago`/`last week`. space-nli's existing `applyPastDates: false` guard is extended from day-granularity to instant-granularity for results with *known* date+time components (that is exactly the "ago" family: they assign day+hour as known). Alternative rejected: a `ignorePastDates` option in Chrono — more library surface for a policy only one consumer has; the user explicitly leaned consumer-side.

**D2 — Bare connected hours stay in Chrono; space-nli ignores them standalone.** `at 3` keeps producing an hour-only, meridiem-implied fragment so `tomorrow at 3` still merges into a full datetime. space-nli's date-picking loop currently treats *any* non-time-only-fragment as date-bearing (`TaskInputParser.swift:78`), which is how `test at 3` produced a date pill; it will instead require a known date component (`DateClassifier.hasDateComponent`). Alternative rejected: rejecting bare hours in Chrono outright — would break date+time merging for `tomorrow at 3`, a supported input.

**D3 — Whitespace/comma are no longer connectors; qualified times don't need one.** A numeral qualified by meridiem/minutes/hour-marker (`7pm`, `15:00`, `3h`, `3時`) matches after whitespace or string start (this also fixes EN `3pm` at string start, which today doesn't match at all). A bare numeral needs a real connector word. **Accepted regression:** `tomorrow 8` (and DE `morgen 8`) loses its 8:00 time — users type `tomorrow at 8` or `tomorrow 8am`. This is the price of killing `buy 2 apples` → 02:00 at the library level rather than relying on every consumer to filter.

**D4 — Per-locale hour ranges.** EN/ES/FR/PT: 0–23. DE/NL: 0–24 (`um 24 Uhr`/`om 24 uur` = midnight — existing convention, calendar overflow to next-day 00:00 is semantically correct there). JA: 0–29 (late-night notation, `27時` = next-day 03:00 is correct). Minutes: 0–59 everywhere, including the `H:MM`/`H時M分` forms that today accept 80/99. Out-of-range ⇒ reject the whole match; never overflow.

**D5 — Seconds removal is per-pattern, not per-dictionary-entry-only.** EN: `ENTimeUnitAgoFormatParser`, `ENTimeUnitLaterFormatParser`, `ENTimeUnitWithinFormatParser`, `ENTimeUnitCasualRelativeFormatParser` (incl. the `s` abbreviation), `ENRelativeDateFormatParser`. DE: relative/within/time-expression second groups + `s` abbrev. NL: relative/within parsers + `sec`/`seconde(n)` dictionary entries. ES: within-parser + `seg`/`segundo(s)` entries. FR/PT/JA have none — the PT trap is that `em 30 segundos` currently matches "30" as hour 30 via the bare-number bug; D3+D4 close that hole.

**D6 — Duration phrases stop matching, per locale.** EN: drop `for` from the within-parser (keep `within`/`in`). DE: drop `während`/`waehrend` from the within-parser; require a real direction word so `etwa`/`ungefähr` alone no longer implies future; make `vor` mandatory in the weeks-ago pattern (bare `3 Wochen` currently matches). NL: `N uur` requires a time connector (`om`/`tegen`/`rond`/…); `voor` is deliberately NOT a connector because it means both "before" and "for" — in the app, `voor 2 uur` then falls to DurationScanner as a 2h duration. FR (decided during apply): a bare `Nh` with no connector, no minutes, and no day-period is equally a duration (`3h de travail`) and does NOT match — `à 3h`, `15h30`, and `8h du matin` all stay. JA: hour marker becomes `時(?!間)` so `2時間` (duration) never reads as 02:00. space-nli's DurationScanner already recognizes the bare `2 hours`/`2 uur`/`3h`/`2 Stunden` remnant in all locales.

**D7 — Boundary hardening, not vocabulary changes.** Add left-boundary guards (`(?<!\w)` or explicit start-of-word alternation; for JA, lookbehind/lookahead on the specific characters) to: FR casual keywords (`demain`, `soir`, `midi`), FR time connectors, DE casual time words (`abend`, `nacht`, …), PT relative keywords (`em`, `ha/há`, `faz`), PT time-expression numerals, EN time connectors, JA single-character time words — where for JA the bare `朝`/`夜`/kana forms are removed outright (no word boundaries exist in Japanese; compounds `今朝`/`今夜`/`午前`/`午後` stay). This matches the suffix-guard philosophy already kept in `126dc1c`.

**D8 — Colon times require exactly two minute digits** in every locale (`score 3:2` no longer parses; EN already complies). NL drops the lone-letter `a`/`p` meridiem (`3 a 4 appels`).

**D9 — Leave `AbstractParserWithWordBoundaryChecking` as-is in behavior but stop pretending:** the touched parsers get explicit boundaries in their own patterns (as `126dc1c` did). Auto-wrapping every parser in boundaries via the base class was rejected: it would change matching for all 60+ parsers at once, far beyond this change's verified surface.

**D10 — Verification style.** Each locale change lands with table-driven NO_MATCH/MATCH regression tests mirroring the audit case lists (the empirically verified inputs in this change's spec scenarios are the fixtures). The existing suites (`CommonWordCollisionTests`, merge/refiner tests) must stay green — in particular `tomorrow at 3` merge and `dinner 7pm`.

## Risks / Trade-offs

- [`tomorrow 8` / `morgen 8` lose their time] → Accepted (D3), with one hard constraint: the remaining match span must be exactly the date keyword (`tomorrow`), and the `8` must not be consumed by any match — consumers strip matched spans from the task name, so a swallowed `8` would delete user text. Covered by a span-assertion scenario in `numeric-time-validation`. `tomorrow at 8`, `tomorrow 8am` unaffected. Release notes for consumers.
- [EN merge refiners rely on time fragments produced by the old loose pattern] → Regression tests for `tomorrow at 3`, `friday at 3`, `tomorrow at 15`, `明日の3時` before touching patterns; run the full suite per locale commit.
- [NL `voor 2 uur` ("before 2 o'clock") no longer schedules 2:00] → Accepted: ambiguity is unresolvable; in the app it becomes a 2h duration, which is the more common intent in task input. Users can type `om 2 uur`.
- [DE/NL hour 24 and JA hours 24–29 rely on calendar overflow] → Keep overflow exactly for those documented conventions; range checks reject everything else, so the overflow path is only reachable for valid conventional values.
- [space-nli instant-granularity guard could eat `today at 9am` typed at 10:30] → It does, by design (known day + known time in the past = explicitly past). The implied-day form `at 9am` keeps its current same-day behavior. If this proves annoying, the guard can be relaxed to a small grace window — decision deferred until real usage feedback.
- [Hardcoded test-string shortcuts in `JATimeExpressionParser`/`FRTimeExpressionParser`/JA merge refiners] → Not expanded here; patterns are edited around them. Flagged as tech debt (see Open Questions) since tests may depend on them.
- [Other Chrono consumers] → None known besides space-nli; the removals are breaking but intended. Version bump + changelog.

## Migration Plan

1. Land Chrono changes locale-by-locale (EN first — it defines the pattern-shape conventions; then ES/FR/DE/NL/PT/JA), each with its regression tests; `swift test` green per commit.
2. Bump Chrono version; space-nli tracks `branch: "main"` so a rebuild picks it up.
3. Land space-nli changes (date-bearing filter, instant-granularity past guard, duration-handoff tests); its suite green.
4. Rollback strategy: each locale is an independent commit; revert individually if a regression surfaces.

## Open Questions

- **Dotted numerics as dates** (`1.5 kg` → Jan 5 EN / May 1 ES, `Python 3.11` → Nov 3, `versão 2.5` → May 2): deliberate per `7c3b13b`, but the audit shows heavy false-positive cost in task input across EN/ES/FR/NL/PT. Candidate follow-up change: require a date context (connector/word boundary + no adjacent unit word) or drop no-year dotted forms in non-DE locales. Needs a product decision — DE legitimately writes `3.10.` for dates.
- **`W12`/`week 50` eagerness** (`see cell W12` → ISO week 12): week tokens are a core space-nli feature (`w25` pills), so left untouched; revisit only if real-world noise shows up.
- **Tech debt, separate change:** hardcoded test-string branches in JA/FR time parsers and JA merge refiners; dead `NLConstants.CASUAL_DATE_PATTERN`/`ORDINAL_WORD_DICTIONARY`; `ENPrioritizeWeekNumberRefiner` checking a tag no parser sets; overlapping `ENSlashDateFormatParser`+`ENSlashMonthFormatParser` registration.
