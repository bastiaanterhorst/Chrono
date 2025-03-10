# Approach to Work for Chronos.swift

For detailed ways of working documentation, please refer to the comprehensive [ways-of-working.md](./ways-of-working.md) document.

## Core Principles

1. For any new work that is started, create a git branch.
2. Always base the work that you do off a task from a spec file.
3. Work on only one task at a time.
4. Write tests first, and then write the implementation.
5. After every big change, run a build and run the tests to see if everything works.
6. Do not continue to the next task until it is fully implemented, builds cleanly, and all tests pass.
7. For every substantial change, create a git commit describing the changes that you made.
8. Always make sure that a commit works, so only commit when tests pass and the build compiles.
9. When a feature is fully implemented and you've crossed off the task from the spec file, merge the branch back to main.
10. Return to main if there are issues with the build or with the test suite; fix those first.
