---
description: Reduce code length when linting reports files, classes, or methods are too long
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# Refactor-Shrink Command

Reduce code length to satisfy linting rules about file, class, function, or method size.

## Usage

- `/refactor-shrink` — Auto-detect from recent lint output
- `/refactor-shrink <file>` — Reduce length in a specific file
- `/refactor-shrink <file>:<class>` — Reduce a specific class
- `/refactor-shrink <file>:<method>` — Reduce a specific method

## Process

### 1. Identify What Is Too Long

If no target is specified, run the linter to find length violations:

```bash
make lint 2>&1 | grep -iE '(too long|too many lines|Metrics/(MethodLength|ClassLength|ModuleLength|BlockLength))'
```

Parse the output to identify:
- Which files have violations
- Whether the violation is at file, class, or method level
- The current length vs. the allowed limit
- The specific RuboCop cop name (e.g., `Metrics/MethodLength`)

If a target file or class is provided, focus on that target.

### 2. Ensure Tests Pass

Before making any changes:

```bash
make test
```

If tests do not pass, **stop** and report the failure. Do not refactor broken code.

### 3. Delegate to Refactor-Shrinker Agent

Delegate the analysis and implementation to the `refactor-shrinker` subagent:

```
Task(subagent_type="refactor-shrinker", prompt="
  Reduce the length of the following code that exceeds lint limits:

  File: <file path>
  Violation: <cop name> — <current length> lines (limit: <allowed>)
  Target: <file|class|method name>

  Current lint output:
  <paste relevant lint lines>
")
```

Provide the agent with:
- The file path(s)
- The specific lint violation(s) and line counts
- The target limits to achieve

### 4. Verify Results

After the agent completes:

```bash
make ci
```

Confirm that:
- The specific lint violations are resolved
- No new lint violations were introduced
- All tests still pass

### 5. Report Results

Summarize what was done:

```
Refactor-shrink complete.

Before: <file> — <N> lines (<violation details>)
After:  <file> — <M> lines (within limit)

Changes:
- Extracted <ClassName> to <new_file> (<X> lines)
- Extracted methods: <method1>, <method2> (<Y> lines saved)
- Removed dead code: <description> (<Z> lines)
- Inlined <method> (<W> lines saved)

All tests pass. No new lint violations.
```

## Multiple Violations

When multiple violations exist, process them in this order:
1. Largest methods first (most impact, easiest to extract)
2. Then classes (may require new files)
3. Then files (may require architectural changes)

## Important

**Never ignore or disable a linting rule.** Always reduce the code to satisfy the rule. If the code is clean and cohesive at its current length and reduction would harm quality, ask the user whether to adjust the lint limit — do not suppress the rule or add a disable comment.

## What Comes Next

After `/refactor-shrink`:
- `/review` — Verify quality of the extractions
- `/pre-commit` — Prepare for commit
