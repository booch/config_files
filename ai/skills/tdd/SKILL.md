---
name: tdd
description: Test-Driven Development methodology. Use this skill when writing tests, when the user asks for TDD, when implementing new features that need tests, or when the user says "write tests first" or similar. This skill focuses on the RED phase — writing failing tests that specify behavior.
---

# TDD Skill

This skill guides Test-Driven Development, focusing on writing tests as executable specifications before implementation.

## Core Principles

### Tests as Specifications

Tests are not just verification — they are **executable specifications** that document how the system should behave. A well-written test suite is living documentation.

### API Design Through Testing

Tests are the **first consumers** of your API. Writing tests first means:

- You design the interface before implementation
- Awkward tests reveal awkward APIs
- The caller's perspective drives design decisions

### Red-Green-Refactor

The classic TDD cycle:

1. **RED**: Write a failing test
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve while keeping tests green

This skill focuses on the RED phase. GREEN and REFACTOR are handled by `/build` and `/refactor`.

## When to Use This Skill

- User explicitly requests TDD or "tests first"
- Implementing new behavior that needs verification
- Fixing a bug (write a test that reproduces it first)
- Refactoring (ensure tests exist before changing code)

## Test Writing Process

### 1. Understand the Requirement

Before writing any test:

- What behavior is being specified?
- What are the inputs and expected outputs?
- What edge cases exist?
- What errors should be handled?

If unclear, **ask clarifying questions first**.

### 2. Design the API

Think about how the test will call the code:

```ruby
# What interface would be convenient?
result = Calculator.add(2, 3)  # Simple and clear

# vs.
calc = Calculator.new
calc.set_operand1(2)
calc.set_operand2(3)
result = calc.perform_addition  # Awkward
```

Let the test drive the API toward simplicity.

### 3. Write the Test

Structure using AAA (Arrange-Act-Assert):

```ruby
describe Calculator do
  describe "#add" do
    it "returns the sum of two positive integers" do
      # Arrange
      calculator = Calculator.new
      
      # Act
      result = calculator.add(2, 3)
      
      # Assert
      expect(result).to eq(5)
    end
  end
end
```

### 4. Verify the Test Fails

Run the test to confirm it fails **for the right reason**:

- ✅ `NameError: uninitialized constant Calculator` — Good, class doesn't exist
- ✅ `NoMethodError: undefined method 'add'` — Good, method doesn't exist
- ❌ Test passes — Something is wrong, the behavior already exists

### 5. Present for Review

Before implementation:

```
I've written these tests to specify the behavior:

[tests]

They verify:
- [behavior 1]
- [behavior 2]

The tests currently fail because [reason].

Ready to implement?
```

## Test Quality Guidelines

### One Behavior Per Test

Each test should have one reason to fail:

```ruby
# Good: One behavior
it "returns nil when the key doesn't exist" do
  expect(cache.get("missing")).to be_nil
end

# Bad: Multiple behaviors
it "handles missing keys and expired keys" do
  expect(cache.get("missing")).to be_nil
  expect(cache.get("expired")).to be_nil
end
```

### Descriptive Names

Test names should read as specifications:

```ruby
# Good: Describes behavior
it "raises ArgumentError when amount is negative"

# Bad: Describes implementation
it "calls validate_amount method"
```

### Avoid Database When Possible

Don't hit the database unless testing database behavior:

```ruby
# Good: In-memory object
user = User.new(name: "Craig", role: :admin)

# Avoid: Database persistence
user = User.create!(name: "Craig", role: :admin)
```

### Minimal Mocking

Prefer real objects over mocks. When mocking is necessary:

- Mock roles/interfaces, not concrete implementations
- Keep mock setup simple
- Complex mocking often signals design problems

## Language-Specific Patterns

### Ruby (RSpec)

```ruby
RSpec.describe ClassName do
  describe "#method_name" do
    context "when condition" do
      it "behaves this way" do
        # Arrange
        subject = ClassName.new(dependency: fake_dependency)
        
        # Act
        result = subject.method_name(args)
        
        # Assert
        expect(result).to eq(expected)
      end
    end
  end
end
```

### JavaScript (Jest/Vitest)

```javascript
describe("ClassName", () => {
  describe("methodName", () => {
    it("behaves this way when condition", () => {
      // Arrange
      const subject = new ClassName({ dependency: fakeDependency });
      
      // Act
      const result = subject.methodName(args);
      
      // Assert
      expect(result).toBe(expected);
    });
  });
});
```

## Integration with Workflow

This skill produces tests. Related skills/commands:

- `/build` — Implement code to pass the tests
- `/refactor` — Improve code while keeping tests green
- `/review` — Code review after implementation
