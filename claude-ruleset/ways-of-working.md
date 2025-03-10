# Ways of Working: Chronos.swift Development Guidelines

This document outlines our standardized approach to development on the Chronos.swift project. Following these guidelines ensures a consistent, high-quality codebase that is maintainable and robust.

> **Note**: For a quick reference of core principles, see the [approach-to-work.md](./approach-to-work.md) document.

## Git Workflow

1. **Branch-Based Development**
   - Create a new git branch for any new work that is started
   - Branch naming convention: `feature/feature-name` or `bugfix/issue-description`
   - Always branch from the latest `main` branch

2. **Task-Based Development**
   - All work must be based on a task from a spec file in the `claude-specs` directory
   - Each branch should correspond to a specific task or related set of tasks

3. **Commit Guidelines**
   - Create a git commit for every substantial change
   - Write descriptive commit messages explaining what changes were made
   - Only commit when tests pass and the build compiles successfully
   - Include references to spec tasks in commit messages when applicable

4. **Merging**
   - When a feature is fully implemented and the task is crossed off in the spec file, merge the branch back to `main`
   - Use pull requests for code reviews when collaborating with others
   - Delete branches after merging to keep the repository clean

## Development Process

1. **Task Selection**
   - Work on only one task at a time
   - Complete the current task fully before moving to the next one
   - Mark tasks as in-progress in spec files while working on them

2. **Test-Driven Development**
   - Write tests first, then write the implementation
   - This ensures that your code is testable and meets requirements from the start

3. **Quality Control**
   - Run a build and the test suite after every significant change
   - Do not continue to the next task until the current one:
     - Is fully implemented
     - Builds cleanly
     - Passes all tests
   - Update documentation as necessary

4. **Issue Resolution Priority**
   - If there are issues with the build or test suite, fix those first before proceeding with feature work
   - Return to `main` branch if necessary to address critical issues

## Code Standards

1. **Swift Guidelines**
   - Follow Swift API design guidelines
   - Maintain consistent code formatting
   - Write self-documenting code with descriptive method and variable names

2. **Documentation**
   - Document all public APIs with proper Swift documentation comments
   - Keep spec files updated with implementation details
   - Cross off completed tasks in spec files

3. **Testing**
   - Maintain high test coverage
   - Test edge cases and failure modes
   - Write both unit and integration tests as appropriate

## Example Workflow

1. Identify a task in a spec file
2. Create a new branch: `git checkout -b feature/task-name`
3. Write tests for the new functionality
4. Implement the feature to pass the tests
5. Run the build and test suite: `swift build && swift test`
6. Commit changes: `git commit -m "Implement feature X as described in spec Y"`
7. Cross off the task in the spec file
8. Merge back to main: `git checkout main && git merge feature/task-name`
9. Delete the feature branch: `git branch -d feature/task-name`
10. Pull latest changes before starting a new task: `git pull origin main`