# Tasks: Scope down eager parsing

## 1. Regression-test scaffolding (Chrono)

- [x] 1.1 Add `Tests/ChronoTests/ParsingScopeTests.swift` with a table-driven helper asserting NO_MATCH / MATCH per locale, seeded with the verified audit cases from the three spec files (reference date 2026-07-16 10:30)
- [x] 1.2 Add merge-protection MATCH cases before any pattern edits: `tomorrow at 3`, `tomorrow at 15`, `friday at 3`, `dinner 7pm`, `gym 15:00`, `morgen om 15:00` (NL), `amanhã às 15h` (PT), `明日の3時` (JA), `à 3h` (FR), `um 24 Uhr` (DE)
- [x] 1.3 Add match-span assertions: `tomorrow 8` (EN) and `morgen 8` (DE) parse with matched text exactly `tomorrow`/`morgen` — the trailing `8` is not part of any result's text and no hour is set

## 2. English

- [x] 2.1 `ENCasualDateParser`: remove `now` from the pattern and its extract branch
- [x] 2.2 Remove seconds units from `ENTimeUnitAgoFormatParser`, `ENTimeUnitLaterFormatParser`, `ENTimeUnitWithinFormatParser`, `ENTimeUnitCasualRelativeFormatParser` (incl. the `s` abbreviation), `ENRelativeDateFormatParser`
- [x] 2.3 `ENTimeUnitWithinFormatParser`: drop `for` from the prefix alternation (keep `within`/`in`)
- [x] 2.4 `ENTimeExpressionParser`: require word-boundary connector (`at`/`from`/`before`/`after`/`until`) + whitespace for bare hours; allow whitespace/string-start for qualified times (meridiem or `:MM`); drop `,`/bare-`\s` connectors; enforce hour 0–23, minute 0–59 (reject, don't overflow); digit boundaries around numerals
- [x] 2.5 `ENSimpleTimeParser`: enforce hour 0–23 / minute 0–59 on the `H:MM` form; delete the stray debug `print`
- [x] 2.6 Run EN suite; update existing tests that asserted `now`/seconds/`for`/overflow behavior

## 3. Spanish

- [x] 3.1 `ESCasualDateParser`: remove `ahora`; add the missing leading word-boundary guard
- [x] 3.2 `ESTimeUnitWithinFormatParser` / `ESConstants`: remove `seg`/`segundo`/`segundos` units
- [x] 3.3 `ESTimeExpressionParser`: same connector/boundary/range rules as 2.4 (connectors `a las`/`a la`/`al`/`las`; drop `,`/bare-`\s`)

## 4. French

- [x] 4.1 `FRCasualDateParser`: remove `maintenant`; add word boundaries so `lendemain`/`soirée` don't match `demain`/`soir`
- [x] 4.2 `FRCasualTimeParser`: bound `midi`/`minuit` (no match inside `après-midi`); fix the `\a` (BEL) typo in the prefix group
- [x] 4.3 `FRTimeExpressionParser`: word-boundary the connector group (`de`/`a` must not match word tails); enforce hour 0–23, minute/second 0–59
- [x] 4.4 `FRSpecificTimeExpressionParser`: require two-digit minutes after `:` (kills `score 3:2`); add left boundary; enforce ranges

## 5. German

- [x] 5.1 `DECasualDateParser`: remove `jetzt`
- [x] 5.2 Remove second units (`sekunde(n)`/`sek`/`s`) from `DETimeUnitRelativeFormatParser`, `DETimeUnitWithinFormatParser`, `DETimeExpressionParser` seconds group, and `DEConstants.TIMEUNIT_DICTIONARY`
- [x] 5.3 `DETimeUnitWithinFormatParser`: drop `während`/`waehrend`; `DETimeUnitRelativeFormatParser`: require a real direction word (approximation words `etwa`/`ungefähr` alone must not match)
- [x] 5.4 `DERelativeWeekParser`: make `vor` mandatory in the weeks-ago pattern (bare `3 Wochen` must not match)
- [x] 5.5 `DETimeExpressionParser`: require the `um`-style connector for bare hours (kill bare `\s`-preceded numbers and the `[.,]` decimal forms `2,50`/`2.0`); keep hour range 0–24; minute 0–59; fix the unanchored `T` prefix
- [x] 5.6 `DECasualTimeParser`: add leading word boundary (no `Feierabend` → `abend`); make it case-insensitive while at it
- [x] 5.7 (discovered during apply) `DEMonthNameParser`: support day-before-month (`15. März`) — the standard German form never parsed; the old bare-number bug had been masking it in tests
- [x] 5.8 (discovered during apply) `DETimeUnitRelativeFormatParser`/`DETimeUnitWithinFormatParser`: make case-insensitive — capitalized units (`in 5 Stunden`) never matched; the bare-number bug had been producing a bogus 05:00 instead

## 6. Dutch

- [x] 6.1 `NLCasualDateParser`: remove `nu`
- [x] 6.2 Remove second units (`sec`/`seconde`/`seconden`) from `NLConstants` and both relative/within parsers
- [x] 6.3 `NLTimeExpressionParser`: require a time connector (`om`/`tegen`/`rond`) for the `N uur` and bare forms — deliberately excluding `voor`; drop the lone-letter `a`/`p` meridiem branch; hour range 0–24, minute 0–59; keep `H:MM` with two-digit minutes (drop `.` as time separator so `versie 2.0` stops matching)

## 7. Portuguese

- [x] 7.1 `PTCasualDateParser`: remove `agora`; add leading word boundary
- [x] 7.2 `PTTimeExpressionParser`: make the `às/as` connector mandatory for bare numerals; add digit boundaries (no `20[24]`); hour 0–23, minute 0–59; connector on word boundary
- [x] 7.3 `PTRelativeTimeUnitParser` / `PTRelativeWeekParser` / `PTRelativeUnitKeywordParser`: add leading word boundaries (`it[em] 2 dias`, `apan[ha] 2 dias` must not match)
- [x] 7.4 (discovered during apply) `PTCasualDateParser`: assign (not imply) day/month/year for `hoje`/`amanhã`/`ontem` — PT was the only locale implying, which made the results non-date-bearing for consumers

## 8. Japanese

- [x] 8.1 `JATimeExpressionParser`: change the hour marker to `時(?!間)` (durations `2時間` must not read as clock times); add digit boundaries incl. full-width (no `1[00時]`); hour 0–29, minute 0–59; remove the stray `print`
- [x] 8.2 `JACasualDateParser`: remove the bare single-character alternatives `朝`/`夜`/`あさ`/`よる` (keep `今朝`/`今夜`/`今晩`/`夕方`/`午前`/`午後`)

## 9. Cross-cutting (Chrono)

- [x] 9.1 Verify strict configurations pick up the same time-expression fixes (shared parsers) and still pass
- [x] 9.2 Full `swift test`; fix any test asserting removed behavior; `swift build -c release` sanity
- [x] 9.3 Bump `Version.swift` / changelog noting the breaking removals

## 10. space-nli (cross-repo: ~/code/space-nli)

- [x] 10.1 `TaskInputParser`: date-picking loop uses `DateClassifier.hasDateComponent` (only date-bearing results schedule); standalone non-confident hour fragments are ignored entirely
- [x] 10.2 `TaskInputParser`/`DateClassifier`: when `applyPastDates == false`, drop results with known date+time whose instant < reference (`2 minutes ago`, `yesterday at 3pm`)
- [x] 10.3 Tests: `test at 3` → no date/no time; `test at 3pm` → today 15:00; `tomorrow at 3` → tomorrow 03:00; `2 minutes ago` → nothing; `meeting for 2 hours` → duration token only; `gedurende 2 uur` (NL) → duration token only
- [x] 10.4 Update the Chrono dependency and run the full space-nli suite — verified via a local `swift package edit Chrono` override (77 tests green); the Package.resolved pin bump happens once the Chrono branch lands on main

## 11. Final verification

- [x] 11.1 Re-run the full audit case tables (all locales) from the spec scenarios against the finished build; every NO_MATCH/MATCH expectation green
- [x] 11.2 Confirm settled behaviors untouched: `CommonWordCollisionTests` green (weekday/month abbreviations still parse per 126dc1c); dotted-date behavior unchanged (7c3b13b)
