# Swift Code Guidelines

## Fundamental Principles
- **Clarity at the point of use** is paramount
- **Clarity over brevity** when naming APIs
- **Trust the compiler** for type inference when reasonable
- **Eliminate ambiguity** in function and parameter names
- **Follow the principle of least surprise** in API design
- **Design for evolution** to maintain binary compatibility

## Project Architecture
- Structure code using Swift Package Manager's modular architecture
- Define distinct module boundaries with clear responsibilities
- Use separate targets for platform-specific code
- Create micro-libraries for reusable functionality
- Employ layered architecture patterns (domain/application/infrastructure)
- Follow dependency direction rules (domain → application → infrastructure)
- Apply feature-based organization for complex applications

## Package Organization
- Maintain clean dependency graphs with explicit imports
- Use package plugins for code generation and build process tasks
- Leverage conditional dependencies for platform-specific functionality
- Define clear public API boundaries in Package.swift
- Use library evolution and @available annotations for compatibility
- Keep test resources isolated with dedicated testing targets
- Employ conditional compilation sparingly with `#if` directives

## Formatting & Layout
- Use 2-space indentation (Swift standard)
- Limit line length to 100 characters
- Align multi-line method chains with the dot on new lines
- Group code logically with a single blank line between sections
- Use PascalCase for types; camelCase for properties/methods/variables
- Prefix protocols that describe capabilities with "-able" or "-ible"
- Use trailing closure syntax only when closure is the final parameter
- Prefer early returns to reduce nesting and cognitive load

## Idiomatic Swift
- Prefer Swift's native collection APIs over imperative loops
- Leverage `map`, `filter`, `reduce`, `compactMap`, and `flatMap`
- Use pattern matching with `switch` and `if case let` extensively
- Apply custom operators judiciously and document thoroughly
- Use functional patterns but maintain readability above all
- Prefer named tuple elements over positional access
- Implement domain-specific languages with result builders when appropriate

## File Organization
- One primary type per file, named identically to the file
- Group extensions by protocol conformance or functionality
- Keep files under 400 lines; split by responsibility when larger
- Use // MARK: - Section Name to denote logical sections
- Order properties/methods: public → internal → private
- Group computed properties separately from stored properties
- Follow consistent import order: Swift → system → third-party → internal

## Dependency Management
- Follow inversion of control and dependency injection principles
- Use protocol abstractions at module boundaries
- Prefer explicit dependencies via initializer injection
- Implement service locators for complex dependency graphs
- Avoid singletons and global state; use dependency injection containers
- Apply the interface segregation principle to keep protocols focused
- Use factory patterns for complex object creation

## Type System Mastery
- Use opaque types (`some Protocol`) for better API evolution
- Apply associated types in protocols strategically
- Use phantom types to encode constraints at compile time
- Prefer constrained extensions over inheritance hierarchies
- Implement conditional conformance where it enhances type safety
- Use `where` clauses to express complex generic constraints
- Employ type erasure patterns to hide implementation details

## Concurrency & Safety
- Design for thread safety by using Swift Concurrency primitives
- Employ `actor`s for safe shared mutable state
- Implement Sendable conformance for cross-actor data transfer
- Use Swift Distributed Actors for distributed systems
- Mark properties as `@MainActor` when they must be accessed on main thread
- Utilize Swift's built-in data race detection in debug builds
- Avoid implicit captures in closures with explicit capture lists
- Document threading requirements and invariants

## Testing & Documentation
- Write tests first to ensure proper API design
- Document all public APIs with DocC markdown syntax
- Create executable examples in documentation with `@Example`
- Link related symbols with ``Symbol`` syntax in documentation
- Apply parameterized tests to cover edge cases
- Document threading/concurrency expectations for all APIs
- Add performance tests for critical code paths
- Maintain 90%+ test coverage for core business logic

## Memory Management
- Avoid reference cycles with weak/unowned references
- Prefer value types (structs) for immutable data models
- Use classes only when reference semantics are required
- Explicitly mark escaping closures to document lifetime
- Be explicit about ownership with `[weak self]` capture lists
- Utilize Swift's memory ownership features for performance-critical code
- Prefer local reasoning about memory with clear ownership patterns

## Code Generation & Tooling
- Use Swift macros for compile-time code generation
- Configure SwiftLint for automated style enforcement
- Apply swift-format for consistent code formatting
- Employ SwiftGen for type-safe asset access
- Leverage SourceKit-LSP for IDE integration
- Automate documentation generation with DocC
- Configure continuous integration with proper test matrices