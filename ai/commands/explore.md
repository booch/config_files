---
description: Explore and understand the codebase — with caching for efficiency
allowed-tools: Read, Grep, Glob, Write
---

# Explore Command

Quickly understand a codebase or specific area of code, with cached results for efficiency.

## Usage

- `/explore` — Get overview of current project
- `/explore <path>` — Explore specific directory or file
- `/explore <question>` — Answer a question about the codebase
- `/explore --refresh` — Force refresh of cached exploration

## How It Works

### 1. Check Cache

Look for existing exploration data in `.ai/explorer-cache/`:

```
.ai/explorer-cache/
├── structure.json      # Directory structure and file types
├── dependencies.json   # Package dependencies and imports
├── patterns.json       # Identified architectural patterns
├── entry-points.json   # Main entry points and APIs
└── last-updated.txt    # Timestamp of last exploration
```

### 2. Validate Cache

Cache is valid if:

- `last-updated.txt` exists and is recent (within 24 hours)
- No significant changes to key files (check git status)
- Exploration depth matches request

If cache is stale or missing, refresh it.

### 3. Explore or Answer

**For overview requests**: Use cached structure, supplement with fresh reads if needed.

**For specific questions**: Search relevant cached data, then drill into code.

### 4. Update Cache

After exploration, update cache with new findings.

## Cache Structure

### structure.json

```json
{
  "directories": {
    "lib/": "Main source code",
    "lib/stone/": "Stone language implementation",
    "lib/stone/ast/": "Abstract Syntax Tree nodes",
    "spec/": "Test specifications"
  },
  "key_files": {
    "lib/stone.rb": "Main entry point",
    "lib/stone/grammar.rb": "Parser grammar",
    "Makefile": "Build commands"
  },
  "file_counts": {
    ".rb": 45,
    ".md": 12,
    "_spec.rb": 30
  }
}
```

### dependencies.json

```json
{
  "runtime": ["grammy", "ruby-llvm", "parslet"],
  "development": ["rspec", "rubocop", "pry"],
  "local": {"grammy": "../grammy"}
}
```

### patterns.json

```json
{
  "architecture": "Parser → Transform → AST → LLVM IR",
  "patterns": [
    {"name": "Visitor", "location": "lib/stone/visitor.rb"},
    {"name": "Value Object", "location": "lib/stone/ast/*.rb"}
  ],
  "conventions": [
    "AST nodes define to_llir() for code generation",
    "Specs serve as language documentation"
  ]
}
```

## Exploration Depth

### Quick (default)

- Directory structure
- Key files identification
- Dependency overview

### Standard

- All of Quick, plus:
- Architectural patterns
- Entry points and APIs
- Code conventions

### Deep

- All of Standard, plus:
- Detailed file analysis
- Cross-file relationships
- Potential issues

## Output Format

```
# Project: Stone

## Overview

Stone is a multi-paradigm programming language...

## Structure

- `lib/stone/` - Core implementation
  - `ast/` - AST node definitions (42 files)
  - `grammar.rb` - Parser grammar
  - `transform.rb` - Parse tree → AST

- `spec/` - Specifications
  - `language/` - Language semantics tests
  - `unit/` - Unit tests

## Key Patterns

- **Parser → Transform → AST → LLVM**: Main compilation pipeline
- **Value Objects**: AST nodes are immutable
- **Visitor Pattern**: Used for tree traversal

## Entry Points

- `Stone.parse(code)` - Parse source to AST
- `Stone.eval(code)` - Parse, compile, execute
- `bin/stone` - CLI (planned)

## Dependencies

- Grammy (local): Parser generator
- ruby-llvm: LLVM bindings

---
*Cache updated: 2025-01-16 14:30*
*Use `/explore --refresh` to force update*
```

## Subagent Integration

The explorer uses a lightweight subagent (Haiku model) for efficient exploration:

- Reads files without polluting main context
- Returns summarized findings
- Updates cache for future use

## Guidelines

- Use cache when available to save tokens
- Refresh cache after significant code changes
- Be specific in questions for better answers
- Deep exploration is expensive — use sparingly
