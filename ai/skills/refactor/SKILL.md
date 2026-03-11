---
name: refactor
description: Code refactoring methodology. Use this skill when improving code structure, when the user asks to simplify or clean up code, when reducing duplication, when improving readability, or after implementing features (the REFACTOR phase of TDD). Focuses on improving code without changing behavior.
---

# Refactor Skill

This skill guides refactoring — improving code structure while preserving behavior.

## Core Principle

**Refactoring changes the structure of code without changing its behavior.**

Tests should pass before refactoring, during refactoring (after each step), and after refactoring.

## When to Use This Skill

- After implementing a feature (TDD's REFACTOR phase)
- When code is hard to understand
- When code is hard to modify
- When duplication is discovered
- When preparing code for a new feature
- When the user asks to "simplify", "clean up", or "improve"

## The Four Rules of Simple Design

Refactor toward these goals (in priority order):

1. **Passes the tests** — Behavior must be preserved
2. **Reveals intention** — Code should explain itself
3. **No duplication** — DRY (but don't over-abstract)
4. **Fewest elements** — Remove unnecessary code

## Refactoring Process

### 1. Ensure Tests Exist

Before touching code:

```bash
make test  # Must pass
```

If tests don't exist for the target code:
- Write tests first, OR
- Ask the user how to proceed

**Never refactor untested code without explicit approval.**

### 2. Identify Opportunities

Look for code smells:

**Size Issues**
- Long methods (>10 lines, ideally <5)
- Large classes (>200 lines, ideally <100)
- Long parameter lists (>3 parameters)

**Structural Issues**
- Deep nesting (>2 levels)
- Complex conditionals
- Feature envy
- Data clumps

**Duplication**
- Copy-pasted code
- Similar algorithms
- Parallel hierarchies

**Naming Issues**
- Non-descriptive names
- Misleading names
- Inconsistent naming

### 3. Plan the Refactoring

Choose refactorings that address the identified issues:

| Smell | Refactoring |
|-------|-------------|
| Long method | Extract Method |
| Large class | Extract Class |
| Feature envy | Move Method |
| Data clumps | Introduce Parameter Object |
| Complex conditional | Replace with Polymorphism |
| Magic numbers | Replace with Named Constant |
| Unclear name | Rename |
| Dead code | Delete |

### 4. Execute in Small Steps

For each refactoring:

1. Make the change
2. Run tests
3. If tests fail, revert
4. If tests pass, continue

**One refactoring at a time.** Don't batch multiple changes.

### 5. Verify Final State

```bash
make ci  # All tests and linting must pass
```

## Common Refactorings

### Extract Method

```ruby
# Before
def process_order(order)
  # validate
  raise "Invalid" if order.items.empty?
  raise "Invalid" if order.total < 0
  
  # calculate
  subtotal = order.items.sum(&:price)
  tax = subtotal * 0.1
  total = subtotal + tax
  
  # save
  order.update(total: total)
end

# After
def process_order(order)
  validate_order(order)
  total = calculate_total(order)
  order.update(total: total)
end

private def validate_order(order)
  raise "Invalid" if order.items.empty?
  raise "Invalid" if order.total < 0
end

private def calculate_total(order)
  subtotal = order.items.sum(&:price)
  tax = subtotal * 0.1
  subtotal + tax
end
```

### Rename for Clarity

```ruby
# Before
def calc(x, y, z)
  x * y + z
end

# After
def calculate_total_with_shipping(unit_price, quantity, shipping_cost)
  unit_price * quantity + shipping_cost
end
```

### Replace Conditional with Polymorphism

```ruby
# Before
def calculate_area(shape)
  case shape.type
  when :circle then Math::PI * shape.radius ** 2
  when :rectangle then shape.width * shape.height
  when :triangle then 0.5 * shape.base * shape.height
  end
end

# After
class Circle
  def area = Math::PI * radius ** 2
end

class Rectangle
  def area = width * height
end

class Triangle
  def area = 0.5 * base * height
end
```

### Remove Duplication

```ruby
# Before
def format_usd(amount)
  "$#{sprintf('%.2f', amount)}"
end

def format_eur(amount)
  "€#{sprintf('%.2f', amount)}"
end

# After
def format_currency(amount, symbol)
  "#{symbol}#{sprintf('%.2f', amount)}"
end
```

## Guidelines

- **Tests are the safety net** — Don't refactor without them
- **Small steps** — One change at a time
- **Run tests frequently** — After every change
- **Separate from features** — Don't mix refactoring with new behavior
- **Know when to stop** — Good enough is good enough
- **Optimize for readers** — Code is read more than written

## Integration with Workflow

This skill handles the REFACTOR phase. Related:

- `/tdd` — RED phase (write failing tests)
- `/build` — GREEN phase (make tests pass)
- `/refactor` — REFACTOR phase (improve structure)
- `/review` — Verify quality after changes
