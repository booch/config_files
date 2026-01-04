---
name: testing
description: Testing philosophy and practices. This skill should be used when writing tests, designing test strategies, or reviewing test code. Use proactively when discussing TDD, red-green-refactor, test doubles, mocks, stubs, fakes, RSpec, Jest, pytest, unit tests, integration tests, test coverage, or test-first development. (user)
---

# Testing

This skill provides guidance on testing philosophy and practices, emphasizing tests as specifications and API design through TDD.

## Core Philosophy

### Tests as Executable Specifications

Tests are not just verification tools — they are **executable specifications** that document how the system should behave. A well-written test suite serves as living documentation.

### Tests as API Consumers

Tests are the **first users of your code's APIs**. This is why TDD is valuable: you design the API by thinking about the consumer first, before thinking about implementation.

When writing tests:

- Consider what interface would be most convenient for the caller
- Let the test drive the API design
- If the test is awkward to write, the API is awkward to use

## Test-Driven Development (TDD)

### Red-Green-Refactor

The TDD cycle consists of three phases:

1. **Red**: Write a failing test for the next piece of functionality
2. **Green**: Write the minimum code necessary to make the test pass
3. **Refactor**: Improve the code while keeping tests green

Each cycle should be short — ideally minutes, not hours. Small steps reduce risk and provide frequent feedback.

### The Value of TDD

- Forces thinking about the API before implementation
- Produces code with high test coverage by default
- Encourages simpler designs (testable code tends to be well-designed)
- Provides immediate feedback on whether code works
- Creates executable documentation of intended behavior

### Flexible TDD

Strict TDD (one test at a time, red-green-refactor) is the ideal for learning and for complex logic. However, flexibility is acceptable:

**Writing all tests first** is appropriate when:

- Tests need human review/approval before implementation
- The behavior is well-understood and stable
- Documenting a specification before implementing

**Writing tests after** is acceptable when:

- Exploring or prototyping (but add tests before committing)
- The design is genuinely uncertain
- Spiking to learn about a problem

The goal is well-tested code with tests that serve as specifications. The path matters less than the destination, but TDD often produces better results.

### Speed Matters

Tests should be fast. Slow tests discourage running them frequently, which defeats their purpose.

- Target sub-second feedback for unit tests
- Keep the full suite under a few minutes when possible
- Identify and isolate slow tests

## Database Access

**Avoid hitting the database in tests** except when:

- Testing database-specific functionality (queries, constraints, transactions)
- Integration tests that specifically verify database behavior

Do not hit the database just to:

- Populate models or data structures
- Create test fixtures when in-memory objects would suffice
- Test business logic that happens to use database-backed models

Use factories or builders that create in-memory objects when database persistence isn't the thing being tested.

## Test Structure

### One Thing Per Test

Each test should verify one behavior. This doesn't always mean one assertion — sometimes verifying one behavior requires multiple assertions, especially when tests are slow. But the test should have a single reason to fail.

### AAA Pattern

Structure tests using Arrange-Act-Assert:

1. **Arrange**: Set up the preconditions
2. **Act**: Execute the behavior being tested
3. **Assert**: Verify the expected outcome

Keep each section clearly delineated. If any section is complex, consider extracting helper methods.

### Given-When-Then

The BDD mindset aligns with AAA:

- **Given** (Arrange): The initial context
- **When** (Act): The event or action
- **Then** (Assert): The expected outcome

This framing helps focus on behavior from the user's perspective.

## Mocking and Test Doubles

### Prefer Real Objects

Avoid mocking when possible. Build small, simple components with immutable data to reduce the need for mocks.

### When Mocking is Necessary

If mocking is unavoidable:

- **Mock roles, not objects** — mock interfaces/behaviors, not concrete implementations
- **Prefer fakes over mocks** — fakes (simplified implementations) are often clearer than mock expectations
- Keep mock setups simple; complex mocking often signals design problems

### Signs of Excessive Mocking

- Tests that are mostly mock setup
- Mocks returning mocks
- Tests that break when implementation details change
- Difficulty understanding what's actually being tested

Consider these as signals to refactor the production code.

## Custom Matchers

Use custom matchers (RSpec matchers, Jest matchers, etc.) to make assertions readable and intention-revealing.

Good:
```ruby
expect(order).to be_fulfilled
expect(user).to have_permission(:admin)
```

Less clear:
```ruby
expect(order.status).to eq("fulfilled")
expect(user.permissions).to include("admin")
```

Custom matchers:

- Make tests read like specifications
- Provide better failure messages
- Encapsulate complex assertions
- Can be reused across tests

## Language-Specific Guidelines

### Ruby (RSpec)

- Use RSpec as the primary testing framework
- Prefer `describe` for classes/methods, `context` for states/conditions
- Use `let` for lazy-evaluated test data
- Use `subject` for the thing being tested
- Prefer `expect` syntax over `should`
- Use `before` sparingly; prefer explicit setup in each test when clarity matters
- Create custom matchers for domain-specific assertions
- Use `shared_examples` for common behavior across contexts
- Use FactoryBot for test data, but prefer `build` over `create` when persistence isn't needed

```ruby
RSpec.describe Order do
  describe "#fulfill" do
    context "when all items are in stock" do
      it "marks the order as fulfilled" do
        order = build(:order, :with_available_items)
        
        order.fulfill
        
        expect(order).to be_fulfilled
      end
    end
  end
end
```

### JavaScript (Jest/Vitest)

- Use descriptive test names that read as specifications
- Use `describe` blocks to group related tests
- Prefer explicit assertions over snapshot tests (unless testing UI output)
- Use `beforeEach` for common setup
- Mock external dependencies, not internal modules

```javascript
describe("Order", () => {
  describe("fulfill", () => {
    it("marks the order as fulfilled when all items are in stock", () => {
      const order = buildOrder({ items: availableItems });
      
      order.fulfill();
      
      expect(order.isFulfilled()).toBe(true);
    });
  });
});
```

### Bash (BATS or similar)

- Test scripts by testing their behavior, not their output format
- Use temporary directories for file-based tests
- Clean up test artifacts in teardown
- Test error conditions and exit codes

## Test Smells

Watch for these warning signs:

- **Slow tests**: Usually means too much real I/O or database access
- **Flaky tests**: Often timing issues or shared state
- **Fragile tests**: Breaking when implementation changes, not behavior
- **Mystery guests**: Test data coming from somewhere non-obvious
- **Eager tests**: Testing too many things at once
- **Obscure tests**: Hard to understand what's being tested
