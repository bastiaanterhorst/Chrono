# casual-parsing-scope

Defines what Chrono's casual configurations must and must not recognize, across all locales (EN, ES, FR, DE, NL, PT, JA).

## ADDED Requirements

### Requirement: "Now"-equivalents are not recognized
The casual configurations SHALL NOT produce a result for bare "now"-equivalent keywords: EN `now`, ES `ahora`, FR `maintenant`, DE `jetzt`, NL `nu`, PT `agora`. (JA has no now-keyword today; none SHALL be added.) Other casual keywords in the same parsers (`today`, `tomorrow`, `tonight`, and locale equivalents) are unaffected.

#### Scenario: English "now" is ignored
- **WHEN** parsing `do it now` with the EN casual configuration
- **THEN** no result is produced

#### Scenario: Dutch "nu" is ignored
- **WHEN** parsing `doe het nu even` with the NL casual configuration
- **THEN** no result is produced

#### Scenario: Sibling casual keywords keep working
- **WHEN** parsing `tomorrow` (EN), `morgen` (DE/NL), `demain` (FR), `mañana` (ES), `amanhã` (PT), `明日` (JA)
- **THEN** each produces a result for the following day

### Requirement: Second-granularity relative expressions are not recognized
Relative time-unit parsers SHALL NOT match second units in any locale, including abbreviations (EN `seconds` and the `s` in `+30s` — this spans ENTimeUnitAgo/Later/Within, ENTimeUnitCasualRelative, and ENRelativeDateFormat parsers; DE `Sekunden`/`s`; NL `seconden`/`sec`; ES `segundos`; FR/PT/JA currently have no second units and SHALL NOT gain them). Minute-and-coarser units remain. Explicit ISO-8601 timestamps (e.g. `2026-07-16T10:30:45`) keep their second components.

#### Scenario: "in 30 seconds" is ignored
- **WHEN** parsing `in 30 seconds` (EN), `in 30 Sekunden` (DE), `over 30 seconden` (NL), `en 30 segundos` / `dentro de 30 segundos` (ES)
- **THEN** no result is produced

#### Scenario: "30 seconds ago" is ignored
- **WHEN** parsing `30 seconds ago` (EN), `30 seconden geleden` (NL), `vor 30 Sekunden` (DE)
- **THEN** no result is produced

#### Scenario: Abbreviated second units are ignored
- **WHEN** parsing `ping me +30s`, `next 5 seconds`, or `30 seconds from now` (EN)
- **THEN** no result is produced

#### Scenario: Minute granularity still parses
- **WHEN** parsing `in 2 minutes` (EN)
- **THEN** a result 2 minutes after the reference instant is produced

#### Scenario: Seconds phrases must not leak into other parsers
- **WHEN** parsing `em 30 segundos` (PT, which has no seconds unit parser)
- **THEN** no parser matches any fragment of the phrase (in particular, `30` is not read as an hour)

### Requirement: Duration phrases are not points in time
Phrases that state a duration SHALL NOT be parsed as a deadline or clock time. Specifically:
- EN: the within-parser SHALL NOT accept `for` (`for 2 hours` no longer parses); `within`/`in` stay.
- DE: the within-parser SHALL NOT accept `während`/`waehrend`; approximation words (`etwa`, `ungefähr`) alone SHALL NOT act as a future direction (`etwa 2 Stunden` no longer parses; `in etwa 2 Stunden` still does); the weeks-ago pattern SHALL require its direction word (bare `3 Wochen` no longer parses).
- NL: `N uur` SHALL only be read as a clock time when preceded by an explicit time connector such as `om`/`tegen`/`rond`/`tot`/`vanaf` (`om 2 uur` parses; bare `2 uur`, `voor 2 uur`, `gedurende 2 uur` do not).
- JA: the hour marker SHALL NOT match inside the duration unit `時間` (`2時間` no longer parses as 02:00).

#### Scenario: English "for 2 hours" is ignored
- **WHEN** parsing `meeting for 2 hours` with the EN casual configuration
- **THEN** no result is produced

#### Scenario: German duration phrases are ignored
- **WHEN** parsing `während 2 Stunden Meeting`, `etwa 2 Stunden`, or `3 Wochen` with the DE casual configuration
- **THEN** no result is produced

#### Scenario: Dutch clock time requires a connector
- **WHEN** parsing `om 2 uur` with the NL casual configuration
- **THEN** a 02:00 clock-time result is produced
- **WHEN** parsing `gedurende 2 uur` or `voor 2 uur`
- **THEN** no result is produced

#### Scenario: Japanese durations are ignored
- **WHEN** parsing `会議は2時間です` or `24時間営業` with the JA casual configuration
- **THEN** no result is produced

#### Scenario: Future-direction relative phrases keep working
- **WHEN** parsing `in 2 hours` (EN), `in 5 Stunden` (DE), `over 2 dagen` (NL), `en 2 horas` (ES), `daqui a 2 dias` (PT), `2日後` (JA)
- **THEN** each produces the expected future result

### Requirement: Past-direction parsing remains a library capability
Chrono SHALL keep parsing explicit past expressions (`yesterday`, `2 minutes ago`, `last week`, and locale equivalents) in casual configurations. Forward-only recognition is a consumer policy (see `forward-only-consumption`), not a library property.

#### Scenario: "yesterday" still parses
- **WHEN** parsing `yesterday` with the EN casual configuration
- **THEN** a result for the previous day is produced

### Requirement: Time-of-day keywords match whole words only
Casual time-of-day keywords SHALL NOT match inside longer words. In particular: FR `demain` not inside `lendemain`, `soir` not inside `soirée`, `midi` not inside `après-midi`; DE `abend`/`nacht` not as suffixes (`Feierabend`); JA SHALL NOT match bare single-character time words (`朝`, `夜`, and kana equivalents) — compound forms (`今朝`, `今夜`, `今晩`, `夕方`, `午前`, `午後`) remain.

#### Scenario: French keywords respect boundaries
- **WHEN** parsing `lendemain`, `une belle soirée`, or `après-midi` with the FR casual configuration
- **THEN** no casual date/time result is produced from the embedded keyword

#### Scenario: German suffix does not match
- **WHEN** parsing `Feierabend vorbereiten` with the DE casual configuration
- **THEN** no result is produced

#### Scenario: Japanese single-character time words do not match
- **WHEN** parsing `朝ごはんを作る` or `深夜まで作業` with the JA casual configuration
- **THEN** no result is produced

### Requirement: Relative keywords respect word boundaries
Relative-expression keywords SHALL NOT match as suffixes of longer words in any locale (e.g. PT `em` inside `item`, PT `ha` inside `apanha`).

#### Scenario: Portuguese keywords respect boundaries
- **WHEN** parsing `item 2 dias` or `apanha 2 dias` with the PT casual configuration
- **THEN** no result is produced
