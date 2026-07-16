# forward-only-consumption

Cross-repo capability: how space-nli (`~/code/space-nli`, `TaskInputParser` / `DateClassifier`) applies Chrono results under its forward-only policy. Chrono itself stays direction-agnostic (see `casual-parsing-scope`).

## ADDED Requirements

### Requirement: Only date-bearing results create a schedule
A Chrono result whose known values contain no date component (day, month, year, weekday, isoWeek, isoWeekYear) SHALL NOT set a schedule by itself. A confident time-only fragment (known hour plus known minute or meridiem) MAY schedule "today at that time" as today; a non-confident hour-only fragment (e.g. `at 3`) SHALL be ignored entirely — no date, no time, no consumed span.

#### Scenario: Ambiguous "at 3" is ignored wholesale
- **WHEN** parsing task input `test at 3`
- **THEN** no schedule and no time are applied, and the task name keeps the full text

#### Scenario: Unambiguous time still schedules
- **WHEN** parsing task input `test at 3pm`
- **THEN** the task is scheduled today at 15:00

#### Scenario: Date plus ambiguous hour still works via merge
- **WHEN** parsing task input `tomorrow at 3`
- **THEN** the task is scheduled tomorrow at 03:00 (Chrono's merge makes the meridiem known)

### Requirement: Explicit past instants are dropped when past dates are not requested
When `applyPastDates` is false, a result whose known values include both a date component and a time component, and whose resolved instant lies before the reference date, SHALL be dropped entirely. This extends the existing day-granularity past guard to instant granularity.

#### Scenario: "2 minutes ago" is not recognized
- **WHEN** parsing task input `2 minutes ago` with `applyPastDates: false`
- **THEN** no schedule and no time are applied

#### Scenario: Past day+time is not recognized
- **WHEN** parsing task input `yesterday at 3pm` with `applyPastDates: false`
- **THEN** no schedule and no time are applied

#### Scenario: Implied-day times are not affected
- **WHEN** parsing task input `at 9am` at 10:30 with `applyPastDates: false`
- **THEN** the task is scheduled today at 09:00 (the day is implied, not stated, so the day-granularity rule applies as before)

### Requirement: Durations are recognized by DurationScanner, not as times
Duration phrases SHALL surface as duration tokens (via DurationScanner), never as schedules. With Chrono no longer matching `for 2 hours` / `gedurende 2 uur` / `2時間` as times, the embedded `2 hours` / `2 uur` SHALL be picked up as a duration.

#### Scenario: "for 2 hours" becomes a duration token
- **WHEN** parsing task input `meeting for 2 hours`
- **THEN** no schedule is applied and `2 hours` is available as a duration token
