# Chrono.swift

A natural language date parser for Swift. This is a port of the JavaScript library [Chrono](https://github.com/wanasit/chrono).

## Features

- Parse natural language dates and times into Swift Date objects
- Support for casual date expressions like "today", "tomorrow", "yesterday"
- Support for specific time formats like "6:30pm", "noon", "midnight"
- Support for weekday mentions like "next Monday", "last Friday"
- Support for relative dates like "2 days ago", "3 weeks from now"
- Support for month names like "January 12", "May 5"
- Support for slash dates like "12/25/2023", "05/15"
- Extendable architecture with parsers and refiners
- Multiple language support:
  - English (EN) - Complete
  - German (DE) - Complete
  - Japanese (JA) - Complete
  - French (FR) - Complete
  - Spanish (ES) - Coming soon
  - Portuguese (PT) - Coming soon
  - Dutch (NL) - Coming soon

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-username/Chrono.swift.git", from: "1.0.0")
]
```

## Usage

```swift
import Chrono_swift

// Parse a date
let results = Chrono.parse(text: "Let's meet tomorrow at 6:30pm")
if let result = results.first {
    print("Date: \(result.start.date)")
    print("Text: \(result.text)")
}

// Get a single date
if let date = Chrono.parseDate(text: "tomorrow at noon") {
    print("Date: \(date)")
}

// Multi-language support
let jaResults = Chrono.ja.casual.parse(text: "明日の午後3時に会議")
let deResults = Chrono.de.casual.parse(text: "Morgen um 15 Uhr")
let frResults = Chrono.fr.casual.parse(text: "demain à 15h")

// All will parse to tomorrow at 3pm in their respective languages
if let jaDate = jaResults.first?.start.date,
   let deDate = deResults.first?.start.date,
   let frDate = frResults.first?.start.date {
    print("All dates representing tomorrow at 3pm:")
    print("Japanese: \(jaDate)")
    print("German: \(deDate)")
    print("French: \(frDate)")
}
```

## Architecture

Chrono.swift is built with a modular architecture:

- **Parsers**: Individual parsers that recognize specific date/time formats
- **Refiners**: Post-processors that refine and merge parsed results
- **Components**: Building blocks representing parts of a date/time

### Customization

You can extend Chrono.swift with your own parsers:

```swift
// Create a custom parser
struct MyCustomParser: Parser {
    func pattern(context: ParsingContext) -> String {
        return "special_date_format"
    }
    
    func extract(context: ParsingContext, match: TextMatch) -> Any? {
        // Parse the matched text into date components
        let components = context.createParsingComponents()
        components.assign(.year, value: 2023)
        components.assign(.month, value: 12)
        components.assign(.day, value: 25)
        return components
    }
}

// Create a custom chrono instance with your parser
var chrono = Chrono.casual.clone()
chrono.addParser(MyCustomParser())

// Use your custom parser
let results = chrono.parse(text: "special_date_format")
```

## License

MIT License