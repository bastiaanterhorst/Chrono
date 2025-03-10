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
- [ ] Create a test suite for English week number parsing covering all expected formats
- [ ] Create a test suite for relative week parsing (next week, last week, in N weeks, etc.)
- [ ] Implement `ENISOWeekNumberParser` for parsing formats like "Week 45", "W45 2023"
- [ ] Implement or extend `ENRelativeWeekParser` for handling relative expressions
- [ ] Determine the most logical and idiomatic way to structure this new capability in the project, and refine this task into a set of subtasks to implement the required functionality for the English locale

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
- [ ] Update documentation and examples
- [ ] Add benchmarks for the new parsers
- [ ] Create example usage patterns for the new functionality
- [ ] Review and ensure complete test coverage

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
