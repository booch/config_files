---
name: design
description: Software design principles and patterns. This skill should be used when making architectural decisions, designing classes or modules, or evaluating code structure.
---

# Software Design

This skill provides guidance on software design principles, emphasizing simplicity, maintainability, and clean architecture.

## The Four Rules of Simple Design

These rules, in priority order, guide all design decisions:

1. **Passes the tests** — The code must work correctly
2. **Reveals intention** — The code clearly expresses what it does
3. **No duplication** — Every piece of knowledge has a single representation (DRY)
4. **Fewest elements** — No unnecessary classes, methods, or code

Rules 2 and 3 are closely related and reinforce each other. When they appear to conflict, favor revealing intention — clarity for the reader takes precedence.

The rules are applied in order: never sacrifice correctness for clarity, never sacrifice clarity for DRY, and never add elements just to reduce duplication.

## SOLID Principles

### Single Responsibility Principle (SRP)

A module should have one, and only one, reason to change.

This means a module should be responsible to one, and only one, actor or stakeholder. When multiple actors depend on the same module, changes for one actor risk breaking functionality for another.

Signs of SRP violations:

- A class that changes for multiple reasons
- Methods that serve different stakeholders
- "And" in class names (e.g., `UserValidatorAndNotifier`)

### Open/Closed Principle (OCP)

Software entities should be open for extension but closed for modification.

Design modules so new functionality can be added without changing existing code.

### Liskov Substitution Principle (LSP)

Subtypes must be substitutable for their base types.

Any code that works with a base type should work correctly with any subtype.

### Interface Segregation Principle (ISP)

Clients should not be forced to depend on interfaces they do not use.

Prefer many small, specific interfaces over one large, general interface.

### Dependency Inversion Principle (DIP)

High-level modules should not depend on low-level modules. Both should depend on abstractions.

Abstractions should not depend on details. Details should depend on abstractions.

## Coupling and Cohesion

**Maximize cohesion, minimize coupling.**

### Cohesion

Cohesion measures how strongly related the responsibilities of a module are. High cohesion means a module does one thing well.

Signs of low cohesion:

- Methods that don't use most of the class's instance variables
- Unrelated methods grouped in the same class
- Difficulty naming the class without using "and" or "or"

### Coupling

Coupling measures the degree of interdependence between modules. Low coupling means modules can change independently.

### Connascence

Connascence provides a framework for understanding and measuring coupling. Two components are connascent if a change to one requires a change to the other.

#### Dimensions of Connascence

- **Strength**: How difficult is it to refactor?
- **Locality**: How close are the coupled components?
- **Degree**: How many components are affected?

#### Types of Static Connascence (weakest to strongest)

1. **Connascence of Name (CoN)**: Components agree on names
   - Weakest form; easy to refactor with rename tools
   
2. **Connascence of Type (CoT)**: Components agree on types
   - Slightly stronger; type changes propagate

3. **Connascence of Meaning (CoM)**: Components agree on value meanings
   - Often appears as magic numbers or strings
   - Refactor to CoN by introducing named constants

4. **Connascence of Position (CoP)**: Components agree on order
   - Common in positional arguments
   - Refactor to CoN using keyword arguments or objects

5. **Connascence of Algorithm (CoA)**: Components agree on algorithm
   - Example: encoder and decoder must use same algorithm
   - Encapsulate the algorithm in a shared module

#### Types of Dynamic Connascence (stronger than static)

1. **Connascence of Execution (CoE)**: Order of execution matters
2. **Connascence of Timing (CoT)**: Timing of execution matters
3. **Connascence of Values (CoV)**: Values must change together
4. **Connascence of Identity (CoI)**: Components must reference same instance

#### Refactoring Guidance

- Prefer weaker forms of connascence over stronger forms
- Reduce the degree of connascence (fewer coupled components)
- Increase locality (keep coupled components close together)
- Convert dynamic connascence to static when possible

## Design Heuristics

- Favor composition over inheritance
- Program to interfaces, not implementations
- Encapsulate what varies
- Strive for loosely coupled designs
- Keep classes focused and small
