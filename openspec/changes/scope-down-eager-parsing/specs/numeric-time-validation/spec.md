# numeric-time-validation

Validity rules for numeric time expressions across all locales. Empirical baseline (reference 2026-07-16 10:30): `buy 2 apples` → 02:00, `test at 27` → tomorrow 03:00, `test at50` → +2 days, `version 2.0` → `on 2` = 02:00, `reunião 2024` → hour 24, `em 30 segundos` → hour 30, `score 3:2` → 03:02, `100時間` → hour 0.

## ADDED Requirements

### Requirement: Bare numerals require an explicit time connector
A numeral carrying no time qualifier (no meridiem, no minutes, no hour marker such as FR/PT `h`, NL `uur`, JA `時`) SHALL parse as an hour only when preceded by an explicit time-connector word (EN `at`/`from`/`before`/`after`/`until`; ES `a las`/`a la`/`al`; DE `um`; NL `om`/`tegen`/`rond`; PT `às`/`as` — final per-locale lists in design.md). Whitespace or a comma alone SHALL NOT act as a connector. The connector match SHALL start at a word boundary and SHALL be separated from the numeral by whitespace.

#### Scenario: Standalone numbers are not times
- **WHEN** parsing `buy 2 apples` (EN), `comprar 2 manzanas` (ES), `kaufe 2 Äpfel` (DE), `comprar 2 maçãs` (PT), `read chapter 12` (EN), or `call, 7` (EN)
- **THEN** no time result is produced

#### Scenario: Connector without whitespace does not match
- **WHEN** parsing `test at50` (EN) or `a las50` (ES)
- **THEN** no result is produced

#### Scenario: Unmatched trailing number is not swallowed by an adjacent date match
- **WHEN** parsing `tomorrow 8` (EN) or `morgen 8` (DE)
- **THEN** a result for tomorrow is produced whose matched text covers only the date keyword (`tomorrow`/`morgen`) — the `8` is not part of any match and no time is set

#### Scenario: Connected bare hour still produces an hour-only fragment
- **WHEN** parsing `test at 3` (EN) or `um 3` (DE)
- **THEN** a result with known hour 3 and implied (not known) meridiem is produced, so date+time merging (`tomorrow at 3`) keeps working and consumers can ignore the standalone fragment

### Requirement: Connectors match whole words only
A time connector SHALL NOT match as the tail of a longer word.

#### Scenario: Connector inside a word does not fire
- **WHEN** parsing `version 2.0` (EN — `on` inside "version"), `commande 3h` (FR — `de` inside "commande"), or `villa 3h` (FR — `a` inside "villa")
- **THEN** no time result is produced

### Requirement: Qualified times parse without a connector
A numeral qualified by a meridiem, minutes, or a locale hour marker SHALL parse when preceded by whitespace or string start (subject to the range and boundary rules below, and to NL's connector requirement for `uur` in `casual-parsing-scope`).

#### Scenario: Qualified times keep working
- **WHEN** parsing `dinner 7pm`, `gym 15:00`, `3pm` (EN), `à 3h` (FR), `amanhã às 15h` (PT), `明日の3時` (JA)
- **THEN** each produces the expected time result

### Requirement: Hours and minutes are range-checked
Minutes MUST be 0–59 in every locale. Hours MUST be within the locale's valid range: 0–23 for EN/ES/FR/PT; 0–24 for DE/NL (24 = midnight convention, e.g. `um 24 Uhr`); 0–29 for JA (late-night convention, e.g. `27時` = 03:00 next day). An out-of-range value SHALL reject the entire match — it MUST NOT overflow through the calendar into later days.

#### Scenario: Out-of-range hours reject the match
- **WHEN** parsing `test at 27`, `pay 50`, `test at 99`, `27:00`, `99:99` (EN), `a las 27` (ES), `à 27h` (FR), `às 27` (PT), `30時` / `99時` (JA)
- **THEN** no result is produced

#### Scenario: Out-of-range minutes reject the match
- **WHEN** parsing `5:80` (EN), `à 5h99` (FR), or `10時70分` (JA)
- **THEN** no result is produced

#### Scenario: Locale conventions inside range still work
- **WHEN** parsing `um 24 Uhr` (DE), `om 24 uur` (NL), or `27時` (JA)
- **THEN** a result meaning midnight (DE/NL) or 03:00 the next day (JA) is produced

### Requirement: Numerals respect digit boundaries
An hour numeral SHALL NOT match inside a longer digit run (neither preceded nor followed by another digit, including full-width digits in JA).

#### Scenario: Digit runs are not partially consumed
- **WHEN** parsing `reunião 2024` (PT — currently matches trailing `24`) or `100時間の作業` (JA — currently matches `00時`)
- **THEN** no time result is produced

### Requirement: Meridiem tokens are locale-valid
NL SHALL NOT accept a lone `a` or `p` as a meridiem (Dutch does not use am/pm letters; `3 a 4` is a numeric range).

#### Scenario: Dutch range "3 a 4" is not a time
- **WHEN** parsing `ik wil 3 a 4 appels` (NL)
- **THEN** no result is produced

### Requirement: Colon times require two-digit minutes
A colon-separated time SHALL require exactly two minute digits, in every locale that accepts `H:MM`.

#### Scenario: Scores and ratios are not times
- **WHEN** parsing `score 3:2` (FR)
- **THEN** no result is produced

#### Scenario: Proper colon times still parse
- **WHEN** parsing `14:30` (EN) or `morgen om 15:00` (NL)
- **THEN** the expected time result is produced
