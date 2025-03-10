# Chrono.swift Development Guide

## Important Notice
- All files in the `claude-ruleset` directory should be regarded as hard rules to always follow while implementing any code or making changes. They are the law of the land and should be loaded and taken into account whenever working on this codebase.
- All files in the `claude-specs` directory describe our project's architecture, features, and implementation details. They are the instructions of what to build. These specifications should be consulted when implementing new features or modifying existing ones.
- When finding issues or improvements that need to be made in the future, add them to the relevant spec file as tasks rather than adding TODO/FIXME comments in source code. This centralizes all work items in the specs.

## Build & Test Commands
- Build package: `swift build`
- Run all tests: `swift test`
- Run single test: `swift test --filter ChronoTests/testName`
- Generate Xcode project: `swift package generate-xcodeproj`
- Debug build with symbols: `swift build -c debug -Xswiftc -g`
- Release build with optimization: `swift build -c release -Xswiftc -O`
- Benchmark: `swift run -c release --skip-build Benchmark`
- Clean build folder: `swift package clean`
- Analyze: `swift package diagnose-api-breaking-changes [--from <version>]`
- Format code: `swift-format format --in-place --recursive .`

## Core Development Guidelines

### Code Principles
- Follow the Swift guidelines in `claude-ruleset/swift-guidelines.md`
- Always run tests before committing changes
- Keep the codebase clean and maintainable
- Use consistent naming conventions

### Development Workflow
- Create a feature branch for each task
- Write tests before implementation
- Document all public APIs
- Get code reviews for all changes
- Always work off a spec file from the `claude-specs` directory
- Always create a detailed implementation plan as part of the spec
- Cross off completed items from the implementation plan as you go so that the list always reflects the current state of the implementation
- Do not change the implementation plan unless discussed with the developer first

### Repository Organization
- `/Sources` - Core implementation code
- `/Tests` - Test suite
- `/Examples` - Example code and usage patterns
- `/Documentation` - Additional documentation
- `/claude-ruleset` - Comprehensive coding standards
- `/claude-specs` - Project specifications and architecture
