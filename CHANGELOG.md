# Changelog

## 0.2.0 — 2026-07-16

Scope-down of eager parsing across all locales (EN, ES, FR, DE, NL, PT, JA).
See `openspec/changes/scope-down-eager-parsing/` for the full specification.

### Breaking — removed recognitions

- **"Now" keywords no longer parse**: EN `now`, ES `ahora`, FR `maintenant`,
  DE `jetzt`, NL `nu`, PT `agora`.
- **Second-granularity relative expressions no longer parse** in any locale
  (`in 30 seconds`, `30 seconds ago`, `+30s`, `en 30 segundos`,
  `over 30 seconden`, `in 30 Sekunden`, …). ISO-8601 timestamps keep seconds.
- **Duration phrases no longer parse as points in time**: EN `for 2 hours`;
  DE `während 2 Stunden`, bare `etwa 2 Stunden`, bare `3 Wochen`; NL bare
  `2 uur`, `voor/gedurende 2 uur`; FR bare `3h` (without minutes, connector,
  or day period); PT bare `3h`; JA `2時間` (時 no longer matches inside 時間).
- **Bare numbers are no longer times**: `buy 2 apples`, `comprar 2 maçãs`,
  `kaufe 2 Äpfel`, `read chapter 12` no longer yield 02:00/12:00. A bare hour
  requires an explicit time connector (`at 3`, `um 3`, `om 3`, `a las 3`,
  `às 3`) on a word boundary followed by whitespace. Consequence: `tomorrow 8`
  matches only `tomorrow` (the `8` is not consumed).
- **Hours and minutes are range-checked** and reject the match instead of
  overflowing into later days: `at 27`, `at50`, `99:99`, `à 27h`, `à 5h99`,
  `às 27`, `um 27`, `10時70分`, `30時` no longer parse. Locale conventions
  stay: DE/NL hour 24 = midnight, JA hours 24–29 = late-night notation.
- **Keywords match whole words only**: `versi[on 2].0`, `comman[de] 3h`,
  `Feier[abend]`, `lendemain`, `soirée`, `après-midi`, `it[em] 2 dias`,
  `apan[ha] 2 dias` no longer produce results. JA bare 朝/夜 removed
  (compounds 今朝/今夜/夕方/午前/午後 stay).
- FR/NL: colon times need two-digit minutes (`score 3:2` is not 03:02);
  NL lone-letter meridiems are gone (`3 a 4 appels` is a range).

### Fixed

- German day-before-month dates now parse: `15. März` → March 15 (never
  worked; masked by the bare-number bug).
- German relative/within unit parsers are case-insensitive: `in 5 Stunden`
  now parses as now+5h (previously hijacked to a bogus 05:00 time).
- French generic time-expression capture groups realigned (could read the
  minute group as the hour, producing hour 30 from `à 15h30`).
- EN `3pm` at string start now parses (previously required a connector).
- Stray debug `print` statements removed from EN/JA time parsers.

### Unchanged by design

- Past-direction parsing (`yesterday`, `2 minutes ago`, `last week`, …)
  remains a library capability; forward-only filtering is consumer policy.
- Dotted numeric dates (`1.5` → a date, per the earlier decision) and
  weekday/month abbreviation vocabulary (EN `sun`/`sat`, ES `mar`, …) are
  untouched.
