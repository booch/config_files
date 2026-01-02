# AI Agent Instructions

This document provides high-level guidance for AI agents working on this codebase.
For detailed instructions on specific topics, see the skills in `skills/`.

## Core Philosophy

Code quality is measured by how easily and cheaply code can be modified for future needs.
Every decision should optimize for simplicity, maintainability, and readability.

## Skills Reference

The following skills provide detailed guidance:

- **sdlc** — Software development lifecycle, including code review process
- **design** — Software design principles (Simple Design, SOLID, coupling/cohesion)
- **code-quality** — Code style, naming, structure, and maintainability
- **testing** — Test philosophy, TDD, and test design
- **security** — Secure coding practices and OWASP Top 10

## Quick Reference

### The Four Rules of Simple Design (in priority order)

1. Passes the tests
2. Reveals intention
3. No duplication (DRY)
4. Fewest elements

### Code Review Process

All significant code changes require 3 sequential code reviews, each by a separate subagent, each followed by refactoring.
See the `sdlc` skill for details.

### Testing Philosophy

- Tests are executable specifications
- Tests are the first consumers of the API — design for the consumer first (TDD)
- Tests should be fast; avoid database access except when testing DB functionality itself
