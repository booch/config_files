---
name: code-quality
description: Code quality guidelines including naming, structure, and maintainability. This skill should be used when writing or reviewing code to ensure it meets quality standards. Use proactively when discussing naming conventions, code smells, readability, Sandi Metz rules, method length, class size, comments, refactoring for clarity, or maintainability concerns. (user)
---

# Code Quality

This skill provides guidance on writing high-quality, maintainable code.

## Core Principle

**The primary indicator of code quality is how easily (quickly/cheaply) code can be modified for future needs.**

All other guidelines serve this goal.

## Maintainability

Code must be easily understood to be maintainable.

### Naming

Choosing good names is one of the most important parts of coding. Invest time in finding names that reveal intention.

- Names should reveal what something does, not how it does it
- Names should be pronounceable and searchable
- Avoid abbreviations unless universally understood
- Use domain vocabulary consistently
- Rename aggressively when better names are discovered

#### Naming Conventions by Type

- **Classes/Modules**: Noun or noun phrase (`UserAccount`, `PaymentProcessor`)
- **Methods/Functions**: Verb or verb phrase (`calculate_total`, `send_notification`)
- **Predicates**: Question form (`valid?`, `has_permission?`, `editable?`)
- **Booleans**: Positive assertions (`enabled`, `visible`, not `not_disabled`)

### Comments

Use comments sparingly:

- Explain "why", not "what"
- Document non-obvious complexity that cannot be clarified through better naming
- Comments are often failures to express intent in code — try renaming first

Avoid:

- Commented-out code (delete it; version control preserves history)
- Comments that restate the code
- TODO comments that linger (create issues instead)

## Sandi Metz's Rules

These rules provide concrete guidelines for keeping code manageable:

1. **Classes should be no longer than 100 lines**
2. **Methods should be no longer than 5 lines**
3. **Pass no more than 4 parameters to a method**
   - Hash/options objects count as parameters
4. **Controllers instantiate only one object**
   - Rails views should know about only one instance variable

### Breaking the Rules

Break these rules only when:

- There is a clear, articulable reason
- The alternative would be worse
- The reason can be explained to another developer

## Code Structure

### Small Functions/Methods

- Each function should do one thing
- Functions should be small enough to understand at a glance
- If you need comments to explain sections, extract those sections into well-named functions

### Immutability

Prefer immutable data structures and avoid mutating state:

- Return new objects rather than modifying existing ones
- Use constants for values that shouldn't change
- Isolate mutation when it's necessary (eg, for performance)

### Avoid Primitive Obsession

Replace primitive types with domain objects when the primitive carries meaning:

- `Email` instead of `String`
- `Money` instead of `Float`
- `DateRange` instead of two `Date` objects

## Language-Specific Guidelines

### Ruby

- Follow the Ruby Style Guide
- Use RuboCop for linting
- Use `attr_reader`, `attr_accessor` appropriately
- Prefer `&&`/`||` over `and`/`or` (except for control flow)

### JavaScript

- Use ESLint with a consistent configuration
- Prefer `const` over `let`
- Use arrow functions for callbacks
- Prefer template literals over string concatenation
- Use destructuring for cleaner code
- Prefer `async`/`await` over raw promises

### Bash

- Use ShellCheck for linting
- Quote variables: `"$var"` not `$var`
- Use `[[ ]]` over `[ ]` for conditionals
- Prefer `$(command)` over backticks
- Set `set -euo pipefail` for safer scripts
- Use functions for reusable logic
- Use lowercase for local variables, UPPERCASE for environment variables
- Define `main` function at the top; call it at the bottom

## Code Smells

Code smells are indicators that something may be wrong with the code.
They don't necessarily mean the code is broken, but they suggest refactoring opportunities.
For each smell found, assess whether it should be refactored.

### The Bloaters

Smells indicating code has grown too large:

- **Long Method**: Methods that try to do too much
- **Large Class / God Class**: Classes with too many responsibilities
- **Long Parameter List**: More than 4 parameters
- **Data Clumps**: Groups of data that appear together repeatedly (extract into a class)
- **Primitive Obsession**: Overuse of primitives instead of small objects

### The Object-Orientation Abusers

Smells indicating misuse of OO principles:

- **Switch Statements**: Often indicate missing polymorphism
- **Refused Bequest**: Subclass doesn't use inherited members
- **Alternative Classes with Different Interfaces**: Similar classes with different method names
- **Temporary Field**: Fields only used in certain circumstances

### The Change Preventers

Smells that make code hard to change:

- **Divergent Change**: One class changed for multiple unrelated reasons (violates SRP)
- **Shotgun Surgery**: One change requires modifying many classes
- **Parallel Inheritance Hierarchies**: Creating a subclass in one hierarchy requires creating one in another

### The Dispensables

Smells indicating unnecessary code:

- **Comments**: Excessive comments often mask unclear names and/or code
- **Dead Code**: Unreachable or unused code
- **Speculative Generality**: Building for hypothetical future needs
- **Duplicate Code**: Same or similar code in multiple places
- **Anemic Class**: A class that doesn't do enough to justify its existence

### The Couplers

Smells indicating excessive coupling:

- **Feature Envy**: Methods that use more of another class than their own
- **Inappropriate Intimacy**: Classes that know too much about each other's internals
- **Message Chains**: Long chains of method calls (`a.b().c().d()`)
- **Middle Man**: A class that only delegates to another class
- **Incomplete Library Class**: Needing to extend library classes because they're missing functionality

### Other Smells

- **Magic Numbers/Strings**: Unexplained literal values
- **Inconsistent Naming**: Same concept with different names, or different concepts with similar names
- **Hidden Dependencies**: Dependencies not visible in the interface
- **Global State**: Mutable shared state that makes behavior unpredictable
