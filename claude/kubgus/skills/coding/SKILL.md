---
name: coding
description: Kubo's rules for writing, editing, fixing or reviewing source code in any language - a feature, a bug fix, a refactor, a test, a one-line change. Use before the first edit to a source file - "implement", "fix this bug", "add a function", "refactor", "write a test", "clean this up". Use it even when the change looks too small to need it - scope creep and defensive code start in small fixes. For a shell script, load shell-scripts as well.
---

# Coding

The repository wins: its context file, formatter and linter config, and the code
around the change override every rule below.

## Scope

- Change what the task needs. A bug fix does not tidy the code around it; a feature
  gets no option nobody asked for. No reformat of lines the change does not touch.
- No comments, docstrings or type annotations on code the change does not touch.
- No helper for a one-time operation, no abstraction for a hypothetical requirement.
  Duplicate until the third copy.
- Delete what your own change leaves dead. Dead code that was there before is his:
  name it, leave it.
- A new dependency, once he approves it, gets a specific version - never `latest`.

## Shape

- Nesting stops at two levels. Guard clauses and early returns keep the happy path
  flat; a complex condition becomes a named function.
- A function does one thing in under 60 lines - unless the split leaves single-use
  fragments that read worse than the whole.
- Keep logic apart from I/O, so a test reaches it without a network or a disk.
- Braces on every block, a one-line body included.
- `switch` for one value against three or more cases, `if`/`else` below that. No
  nested ternaries.
- Private, and `const` or immutable, by default. A loop variable stays scoped to its
  loop.
- The formatter owns line width. Where none runs, wrap at 80 unless the break makes
  the statement harder to read.

## Names and comments

- A function name starts with a verb. A boolean starts with `is`, `has` or `can` and
  reads affirmative: `isVisible`, not `isNotHidden`.
- A comment stays under 128 characters and describes the code, never the change - no
  "now uses", "fixed", "updated to".

## Types and errors

- Validate at system boundaries - user input, files, network, external APIs. Inside
  them, trust the types and the internal code: no fallback, default or `try` for a
  case that cannot occur.
- Fail fast. Never swallow an exception or return a default that hides a failure. An
  error message carries the values that locate the cause, and never a secret.
- Make an invalid state unrepresentable rather than checked for at runtime.
- TypeScript: no `any` - take `unknown` and narrow it at once. No `as` where a type
  guard works.

## Verify

- Before you report done, run the project's own linter, type-checker and tests.
- A bug fix gets a regression test that fails without the fix.
- Tests check the solution; they do not define it. No hard-coded value that passes
  only the test inputs. A test that looks wrong gets reported, not edited to pass.
