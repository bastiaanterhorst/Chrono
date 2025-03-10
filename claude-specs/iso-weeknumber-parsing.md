# ISO Week Number And Relative Week Parsing

## Overview
This specification outlines the implementation of ISO week number parsing functionality for Chrono. The feature will allow users to parse date expressions that include ISO week numbers (e.g., "Week 45" or "W45 2023"). It will also support relative week references like "this week", "last week", "in 2 weeks" and "6 weeks ago".

## Requirements
- Parse expressions containing week numbers according to ISO 8601 standard
- Support various formats: "Week 45", "W45", "Week 45 2023", "2023-W45", "W45-2023"
- Handle relative expressions like "next week", "last week" and others
- Support all currently implemented locales
- Maintain compatibility with existing date parsing functionality
- Return the correct start and end dates for a week (Monday to Sunday, according to ISO standard)
- Add an isoWeek and isoWeekYear property to the known/implied start and end dates, to store the ISO8601 week number (and its corresponding year)
- Handle edge cases where week numbers span across years

## Implementation Plan

### 1: Core project changes
- [x] A parsed date in Chrono returns a set of implied and known values. We need to expand the possible items here to include an ISO week number and ISO week number year. It is important that the ISO week number has its own year, separate from the year of the overall date, as these can differ! (for instance, 30 December 2024 actually falls in week 1 of 2025!) Consider the following subtasks: 
    - [x] Extend the `ParsingComponents` class to include `isoWeek` and `isoWeekYear` properties (Added to Component enum in Types.swift)
    - [x] Update any methods that work with component lists to handle these new properties (Enhanced ParsingComponents.init() to imply ISO week values)
    - [x] Assess if we can add these known and implied values without making changes to all existing parsers. Or, if we do need to make changes, how we can limit those changes as much as possible. In essence, unless we're specifically parsing a week, we want to simply _imply_ the week number and week number year that belongs to the parsed date. Only if we specifically parse a week, we want to set the week number and week number year to known values. (Implementation works with existing parsers)
    - [x] Create utility functions to convert between dates and ISO week numbers/years (Added dateFromISOWeek method)

### 2: English implementation
- [x] Create a test suite for English week number parsing covering all expected formats (Created ENISOWeekNumberParserTests.swift)
- [x] Create a test suite for relative week parsing (next week, last week, in N weeks, etc.) (Created ENRelativeWeekParserTests.swift)
- [x] Implement `ENISOWeekNumberParser` for parsing formats like "Week 45", "W45 2023" (Created ENISOWeekNumberParser.swift)
- [x] Implement or extend `ENRelativeWeekParser` for handling relative expressions (Created ENRelativeWeekParser.swift)
- [x] Add example code demonstrating ISO week number parsing (Created ISOWeekNumberExample.swift)
- [x] Update the EN locale configuration to include the new parsers
- [x] Fix issues with regex capture groups in both parsers
- [x] Address errors with the TextMatch.string(at:) method that's causing "Range X not found" errors
- [x] Fix the problem where week numbers are being mistakenly parsed as hours
- [x] Add better debugging to identify and fix parsing issues

### 3: Dutch implementation
- [ ] Create a test suite for Dutch week parsing covering all expected formats
- [ ] Implement `NLISOWeekNumberParser` for parsing formats like "Week 45", "W45 2023" 
- [ ] Implement or extend `NLRelativeWeekParser` for handling relative expressions
- [ ] Implement the required functionality following the conventions established in the English implementation 

### 4: Other locales
- [ ] German (DE) implementation
    - [ ] Create test suite
    - [ ] Implement parsers
- [ ] Spanish (ES) implementation
    - [ ] Create test suite
    - [ ] Implement parsers
- [ ] French (FR) implementation
    - [ ] Create test suite
    - [ ] Implement parsers
- [ ] Japanese (JA) implementation
    - [ ] Create test suite
    - [ ] Implement parsers
- [ ] Portuguese (PT) implementation
    - [ ] Create test suite
    - [ ] Implement parsers

### 5: Wrapping up
- [x] Update documentation and examples (Created ISOWeekNumberExample.swift)
- [ ] Add benchmarks for the new parsers
- [x] Create example usage patterns for the new functionality
- [x] Review and ensure complete test coverage for English implementation
- [x] Create prioritization mechanism for week number parsers (ENPrioritizeWeekNumberRefiner)
- [x] Fix edge cases with ambiguous patterns (like numbers that could be weeks or hours)

## Technical Specifications

### ISO 8601 Week Date Format
The ISO 8601 standard defines a week date format where:
- Weeks start on Monday
- The first week of the year contains the first Thursday of that year
- Week numbers range from 01 to 53
- Format examples: "Week 12", "Week 23 '24", "Week 33 2026", "2023-W45" or "2023W45" (ISO format)
- Swift's Calendar library provides functionality to compute week numbers for dates and dates for week numbers - we will leverage this for implementation

### Parsing Patterns
Each locale should support the following patterns (adjusted for locale-specific terms):
- Formal formats: "Week 45", "W45", "2023-W45", "2023W45"
- With year variations: "Week 45 2023", "Week 45 '23", "W45/2023"
- Conversational formats: "the 45th week", "week number 45"

### Relative Week Parser
Support for the following patterns:
- Last week
- This week
- Next week
- In N weeks
- N weeks ago
- The week before/after [reference date]
- First/second/third/etc. week of [month/year]

### Parser Implementation Details
Each parser should:
1. Recognize language-specific patterns for week numbers
2. Extract week number and optional year information
3. Convert week number + year to an actual date (typically returning the Monday of that week)
4. Support various formats and expressions according to locale conventions
5. Handle edge cases where week numbers span across years
6. Set appropriate known and implied values in the parsing components

### Integration Points
- The new parsers should be added to their respective locale implementations
- All parsers should work with the existing refiner chain
- Consider creating a base class for the ISO week number parser to be extended by locale-specific implementations
- Integrate with existing date range functionality to support week ranges (e.g., "from week 45 to week 48")

## Implementation Notes

### Lessons Learned
1. **Parser Priority**: When multiple parsers could match the same text, the order in which they're registered is critical.
2. **Component Tagging**: Adding tags to components helps with identification and prioritization in refiners.
3. **Fallback Methods**: Having alternative extraction approaches when regex groups fail improves robustness.
4. **Error Handling**: Robust error handling in text processing prevents cascading failures.
5. **Calendar Calculations**: ISO week calculations require careful handling, especially around year boundaries.
6. **Two-digit Year Handling**: When encountering two-digit years (e.g., "27" or "'23"), apply rules to expand them:
   - For apostrophe years like "'23", prepend "20"
   - For bare two-digit years, use the "sliding window" approach:
     - If the number is < 50, assume 21st century (2000+)
     - If the number is >= 50, assume 20th century (1900+)
7. **Testing Edge Cases**: Create specific test cases for:
   - Abbreviated formats (e.g., "Wk 42" instead of "Week 42")
   - Short year formats (two-digit years)
   - Different separators (space, dash, slash)
   - Year placement (before or after the week number)

### Future Locale Implementations
For implementing ISO week parsing in other locales, follow these guidelines:

1. Study and understand the English implementation as a reference
2. Focus on locale-specific patterns and terminology
3. Reuse the core date calculation logic where possible
4. Ensure proper integration with existing locale-specific parsers
5. Implement the same tagging and assignNull patterns to prevent conflicts
6. Apply consistent two-digit year handling across all locales
7. Support both formal ISO formats (2023-W15) and casual formats in each locale

