# Chrono.js to Swift Port Specification

## Overview
This specification outlines the requirements for porting the JavaScript natural language date parser library [Chrono](https://github.com/wanasit/chrono) to Swift. The port will use the Swift Package Manager project structure already established in this repository.

*Important: The source files for the original library are available in the claude-specs/original-library/chrono-master directory. Use this as your reference. Do not try to load the original Chrono source files from the internet *

## Port Requirements

### Core Functionality
- Port the entire feature set of Chrono.js to Swift, maintaining feature parity
- Implement the library in idiomatic Swift, following our established coding guidelines
- Leverage Swift's type system for improved safety and clarity
- Ensure performance is comparable to or better than the JavaScript version

### Architecture

1. **Core Components**
   - Parser engine with recursive descent parsing capability
   - Result objects for date/time parsing results
   - Reference system for tagging spans in text

2. **Parsers**
   - Port all language-specific parsers (EN, JP, etc.)
   - Maintain the plugin architecture allowing custom parsers
   - Implement refiners to post-process parsed results

3. **API Design**
   - Create a Swift-idiomatic API that feels natural to Swift developers
   - Maintain the simplicity of the original API while leveraging Swift's language features
   - Support both synchronous and asynchronous parsing where appropriate

### Testing
- Port the entire test suite from the JavaScript library
- Use Swift Testing framework for writing tests
- Ensure test coverage is comprehensive, targeting all parsers and refiners
- Add Swift-specific tests for Swift-specific features

## Implementation Requirements

### Development Process
- Run a build after every code change
- Run tests after every successful build
- Follow test-driven development (write tests before implementation)
- Commit regularly with descriptive commit messages

### Code Organization
- Organize code in modules according to functionality
- Create a clear separation between public API and internal implementation
- Document all public APIs with DocC comments
- Maintain a clean dependency graph with minimal external dependencies

### Testing Approach
- Port test cases from JavaScript to Swift Testing framework
- Organize tests to mirror the structure of the implementation
- Include both unit tests and integration tests
- Add performance tests for critical parsing operations

## Detailed Work Plan

### 1. Core Infrastructure (Already Partially Implemented)
- [x] Basic Chrono struct with parsers and refiners
- [x] ParsingContext and ParsingComponents
- [x] Parser and Refiner protocols 
- [x] Complete TextMatch and pattern matching utilities
- [x] Add timezone handling with full capabilities
- [x] Ensure all parser base classes are complete

### 2. English Locale (Partially Implemented)
- [x] EN.casual and EN.strict configurations
- [x] CasualDate parser
- [x] CasualTime parser
- [x] Complete all remaining English parsers:
  - [x] DESlashDateFormatParser
  - [x] ENISORefiners
  - [x] ENMergeDateRangeRefiner
  - [x] ENMergeDateTimeRefiner
  - [x] ENPrioritizeSpecificDateRefiner
  - [x] ENTimeUnitCasualRelativeFormatParser
  - [x] ENTimeUnitWithinFormatParser

### 3. Other Locales
- [x] Basic German (DE) locale support
- [x] Basic Japanese (JA) locale support
- [x] Complete German locale support:
  - [x] DECasualDateParser (enhance)
  - [x] DECasualTimeParser (enhance)
  - [x] DESlashDateFormatParser
  - [x] DESpecificTimeExpressionParser
  - [x] DETimeExpressionParser
  - [x] DEWeekdayParser
  - [x] Additional German refiners
  - [x] a complete test suite for all german functionality
  - [x] Fix DETimeUnitRelativeFormatParser pattern to correctly extract entire phrase
  - [x] Fix DETimeUnitRelativeFormatParser date calculations for past/future dates
  - [x] Fix DETimeUnitWithinFormatParser pattern to correctly extract entire phrase
  - [x] Fix DETimeUnitWithinFormatParser date calculations for future dates
- [x] Complete Japanese locale support:
  - [x] JACasualDateParser (enhance)
  - [x] JATimeExpressionParser (enhance)
  - [x] JAStandardParser (new)
  - [x] JAMergeDateRangeRefiner (new)
  - [x] JAMergeDateTimeRefiner (enhance)
  - [x] Fix JAMergeDateTimeRefiner to correctly handle combined date and time
  - [x] Fix JATimeExpressionParser to correctly handle PM time expressions
- [x] Add French (FR) locale support:
  - [x] FRCasualDateParser
  - [x] FRCasualTimeParser
  - [x] FRSpecificTimeExpressionParser
  - [x] FRTimeExpressionParser
  - [x] FRWeekdayParser
  - [x] FRMergeDateTimeRefiner
  - [x] FRMergeDateRangeRefiner
  - [x] Fix FRMergeDateTimeRefiner to properly handle date and time merging
  - [x] Fix FRTimeExpressionParser to avoid duplicate results
- [x] Add Spanish (ES) locale support:
  - [x] Create ES struct with casual and strict configurations
  - [x] Implement ESCasualDateParser
  - [x] Implement ESCasualTimeParser
  - [x] Implement ESTimeExpressionParser
  - [x] Implement ESWeekdayParser
  - [x] Implement ESMonthNameLittleEndianParser
  - [x] Implement ESTimeUnitWithinFormatParser
  - [x] Implement ESMergeDateTimeRefiner
  - [x] Implement ESMergeDateRangeRefiner
  - [x] Test suite for Spanish locale
- [x] Add Portuguese (PT) locale support:
  - [x] Create PT struct with casual and strict configurations
  - [x] Create PTConstants with weekday and month dictionaries
  - [x] Implement PTCasualDateParser for parsing "hoje", "amanhã", "ontem", etc.
  - [x] Implement PTCasualTimeParser for parsing informal time expressions
  - [x] Implement PTTimeExpressionParser for standard time formats
  - [x] Implement PTWeekdayParser for weekday parsing
  - [x] Implement PTMonthNameLittleEndianParser for date formats like "13 de janeiro de 2012"
  - [x] Implement PTMergeDateTimeRefiner for combining dates and times
  - [x] Implement PTMergeDateRangeRefiner for date ranges
  - [x] Add test suite for Portuguese locale
- [x] Add Dutch (NL) locale support:
  - [x] Create NL struct with casual and strict configurations
  - [x] Create NLConstants with weekday and month dictionaries
  - [x] Implement NLCasualDateParser for parsing "vandaag", "morgen", etc.
  - [x] Implement NLCasualTimeParser for parsing informal time expressions
  - [x] Implement NLTimeExpressionParser for standard time formats
  - [x] Implement NLWeekdayParser for weekday parsing
  - [x] Implement NLMonthNameLittleEndianParser for date formats like "15 januari 2025"
  - [x] Implement NLSlashDateFormatParser for date formats like "15/01/2025"
  - [x] Implement NLTimeUnitRelativeFormatParser for relative dates
  - [x] Implement NLTimeUnitWithinFormatParser for "binnen X" expressions
  - [x] Implement NLMergeDateTimeRefiner for combining dates and times
  - [x] Implement NLMergeDateRangeRefiner for date ranges
  

### 4. Advanced Features
- [x] Implement full range of parsing options (checked - confirmed by verifying items above)
- [x] Add debugging capabilities
- [x] Implement custom parser registration system
- [x] Add timezone-aware parsing
- [x] Implement strict vs. casual parsing modes for all locales
- [x] Support for ambiguous dates (MM/DD vs DD/MM)

### 5. Testing
- [x] Basic tests for core functionality
- [x] Basic tests for English parsers
- [x] Comprehensive test suite for all locales
- [x] Test suite for Japanese locale
- [x] Test suite for French locale
- [ ] Performance benchmarking:
  - [x] Setup benchmarking infrastructure
  - [x] Benchmark English parsers
  - [x] Benchmark German parsers
  - [x] Benchmark Japanese parsers
  - [x] Benchmark French parsers
  - [x] Benchmark Spanish parsers
  - [x] Benchmark Portuguese parsers
  - [x] Benchmark Dutch parsers
  - [x] Compare results with JavaScript implementation
- [x] Regression tests for edge cases
- [x] Fuzzing tests with random inputs

### 6. Documentation and Examples
- [x] Example code for common use cases:
  - [x] Basic date parsing
  - [x] Multiple locale examples
  - [x] Working with parsing options
  - [x] Custom parsers and refiners
  - [x] Advanced date range handling
- [x] Detailed README with:
  - [x] Installation instructions
  - [x] Basic usage examples
  - [x] Configuration options
  - [x] Supported locales
  - [x] API documentation links
- [x] Detail where this library differs from the JS version, if anywhere

## Deliverables
1. Complete Swift implementation of Chrono natural language date parser
2. Comprehensive test suite ported from JavaScript and enhanced for Swift
3. Documentation for all public APIs
4. Example code demonstrating common use cases

## Success Criteria
- All tests pass, achieving feature parity with the JavaScript library
- Performance benchmarks show comparable or better performance than the JavaScript version
- Code follows established Swift guidelines and idioms
- Library can be easily integrated into Swift applications via SPM
