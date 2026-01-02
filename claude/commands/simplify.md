---
description: Review code for simplification opportunities
---

# Simplify Command

Review the specified file(s) or recent changes for simplification opportunities:

1. **Unnecessary abstractions** - Can any classes, modules, or registries be eliminated?
2. **Reuse existing infrastructure** - Are we reinventing something that already exists?
3. **Dead code** - Is there unused code that can be removed?
4. **Inline opportunities** - Can short methods be inlined for clarity?
5. **Over-engineering** - Is there complexity that doesn't earn its keep?

For each issue found:
- Explain what could be simplified
- Show the simpler alternative
- Note any trade-offs

Prioritize readability and maintainability over cleverness.
