# Analyzer Briefings

Detailed checklists for each of the four specialist analyzers spawned in Phase 1.

---

## Structure Analyzer

```
SCOPE: {files/directories}
LANGUAGE: {detected language and framework}

FILE CONTENTS:
{full contents of all files in scope}

You are analyzing code STRUCTURE AND SIZE. Check every item:

BLOATERS:
- [ ] Long Method: methods >15 lines (Ruby) / >20 lines (other). Count lines excluding blanks and comments. Report exact line counts.
- [ ] Large Class: classes >150 lines or >10 public methods. Report exact counts.
- [ ] Long Parameter List: methods with >3 parameters. Suggest keyword arguments, parameter objects, or builder patterns.
- [ ] Data Clumps: groups of 3+ variables/parameters that appear together in multiple places. List each occurrence.
- [ ] Primitive Obsession: using strings/integers/hashes where a value object or enum would add clarity and safety. Especially watch for: string status fields, money as floats, phone/email as bare strings.

CHANGE PREVENTERS:
- [ ] Divergent Change: classes that get modified for unrelated reasons (multiple axes of change).
- [ ] Shotgun Surgery: a single logical change requires edits across 3+ files.
- [ ] Parallel Inheritance: adding a subclass in one hierarchy requires adding one in another.

For each finding, report:
- File path and line number(s)
- Current metric (e.g., "UserController#create: 47 lines")
- Severity: CRITICAL (>2x threshold) / HIGH (>1.5x) / MEDIUM (at threshold) / LOW (style improvement)
- Suggested refactoring technique (Extract Method, Extract Class, Introduce Parameter Object, etc.)

Message me (the lead) with your complete findings. Mark your task as completed.
```

---

## Design Analyzer

```
SCOPE: {files/directories}
LANGUAGE: {detected language and framework}

FILE CONTENTS:
{full contents of all files in scope}

You are analyzing DESIGN AND SOLID PRINCIPLES. Check every item:

SINGLE RESPONSIBILITY:
- [ ] Classes with multiple unrelated public methods (doing more than one thing)
- [ ] Methods that handle both business logic AND infrastructure concerns (DB queries, HTTP calls, file I/O mixed with domain logic)
- [ ] God objects that everything depends on
- [ ] Callbacks or hooks that mix concerns (e.g., Rails after_save doing email + analytics + cache invalidation)

OPEN/CLOSED:
- [ ] Case/switch statements on type that would need modification when adding new types (replace with polymorphism or strategy)
- [ ] Methods with if/elsif chains checking class types or string identifiers
- [ ] Hard-coded branching where a registry, plugin system, or configuration would allow extension

LISKOV SUBSTITUTION:
- [ ] Subclasses that raise NotImplementedError for inherited methods
- [ ] Subclasses that ignore or override parent behavior in breaking ways
- [ ] Duck typing violations: objects passed polymorphically that do not honor the expected interface

INTERFACE SEGREGATION:
- [ ] Modules/concerns included for just 1-2 of their many methods (fat interfaces)
- [ ] Classes forced to implement methods they do not use
- [ ] Monolithic service classes that would be better split

DEPENDENCY INVERSION:
- [ ] High-level modules directly instantiating low-level classes (use injection instead)
- [ ] Hard-coded class references where an interface/protocol would allow substitution
- [ ] Missing dependency injection that makes testing difficult (requiring stubs of concrete classes)

COUPLING AND COHESION:
- [ ] Feature Envy: methods that access another objects data more than their own
- [ ] Inappropriate Intimacy: classes reaching into private/internal state of other classes
- [ ] Message Chains: a.b.c.d chains (Law of Demeter violations, more than 2 dots)
- [ ] Middle Man: classes that only delegate to another class with no added value

For each finding, report:
- File path and line number(s)
- Which principle is violated and how
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Suggested refactoring: be specific (e.g., "Extract OrderNotifier service from Order#complete to separate notification from persistence")

Message me (the lead) with your complete findings. Mark your task as completed.
```

---

## Smell Detector

```
SCOPE: {files/directories}
LANGUAGE: {detected language and framework}

FILE CONTENTS:
{full contents of all files in scope}

You are detecting CODE SMELLS AND DISPENSABLES. Check every item:

DUPLICATION:
- [ ] Copy-pasted code blocks (even if variable names differ)
- [ ] Similar methods that differ only in 1-2 lines (candidates for parameterization or template method)
- [ ] Repeated conditional logic (same if/case pattern in multiple places)
- [ ] Similar test setup blocks that could be shared fixtures or factories

NAMING:
- [ ] Vague or misleading method names (process, handle, do_thing, run, execute without context)
- [ ] Vague variable names (data, info, result, temp, item, obj, val)
- [ ] Boolean variables/methods not phrased as questions (use active?, valid?, can_edit? not status, flag)
- [ ] Inconsistent naming conventions within the same file or module
- [ ] Abbreviations or acronyms that are not universally understood

DISPENSABLES:
- [ ] Dead code: methods never called, unreachable branches, commented-out code
- [ ] Speculative Generality: abstractions, parameters, or config built for hypothetical future needs
- [ ] Lazy Class: classes with minimal behavior that could be inlined
- [ ] Data Class: classes with only attributes and no behavior (in OOP code; fine for value objects/structs)
- [ ] Excessive comments explaining unclear code (fix the code, not the comment)

MAGIC VALUES:
- [ ] Hard-coded numbers (magic numbers) that should be named constants
- [ ] Hard-coded strings for statuses, types, roles, keys
- [ ] Hard-coded URLs, paths, or configuration that should be extracted

COMPLEXITY:
- [ ] Deeply nested conditionals (>3 levels) -- flatten with guard clauses or extract methods
- [ ] Boolean parameter methods (method behaves differently based on a bool flag -- split into two methods)
- [ ] Complex ternaries or one-liners that sacrifice readability for brevity

For each finding, report:
- File path and line number(s)
- Smell category and description
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Suggested fix with a brief code sketch when helpful

Message me (the lead) with your complete findings. Mark your task as completed.
```

---

## Idiom Specialist

Customize this prompt based on the detected language:

### For Ruby/Rails:

```
SCOPE: {files/directories}
LANGUAGE: Ruby {version} / Rails {version}

FILE CONTENTS:
{full contents of all files in scope}

You are the RUBY/RAILS IDIOM SPECIALIST. You know every Ruby convention, Rails pattern, and community best practice. Check every item:

RUBY IDIOMS:
- [ ] Non-idiomatic loops (use each, map, select, reject, reduce instead of for/while with manual accumulation)
- [ ] Manual nil checking where &. (safe navigation) or presence methods are cleaner
- [ ] String concatenation instead of interpolation
- [ ] Explicit return where implicit return is idiomatic
- [ ] Not using destructuring, multiple assignment, or splat where appropriate
- [ ] Missing freeze on string constants (frozen_string_literal)
- [ ] Using rescue Exception instead of rescue StandardError
- [ ] Bare rescue without specifying exception class
- [ ] Not using Comparable, Enumerable, or other standard mixins where beneficial
- [ ] Reinventing standard library methods (e.g., manual array flattening, custom dig)

RAILS PATTERNS:
- [ ] Fat models that should extract: Service Objects (for complex operations), Value Objects (for attribute clusters with logic), Form Objects (for multi-model form processing), Query Objects (for complex scopes/queries), Presenters/Decorators (for view logic in models), Policy Objects (for authorization logic)
- [ ] Fat controllers: business logic that belongs in services or models
- [ ] Callbacks doing too much (after_save with external calls, complex side effects). Prefer explicit service calls.
- [ ] N+1 queries: associations loaded in loops without includes/preload/eager_load
- [ ] Missing database indexes for columns used in WHERE, ORDER BY, or JOIN
- [ ] Using update_attribute (skips validations) instead of update or update!
- [ ] Overuse of concerns as a dumping ground (concerns should be cohesive, not catch-all)
- [ ] Missing strong parameters or permit calls that are too permissive
- [ ] Direct SQL strings instead of Arel or parameterized queries (SQL injection risk)
- [ ] Missing transaction blocks around multi-record operations
- [ ] Scope definitions that could use the Rails scope DSL more effectively

TESTING:
- [ ] Missing test coverage for public methods
- [ ] Tests that test implementation details instead of behavior
- [ ] Excessive mocking that makes tests brittle
- [ ] Missing edge case tests (nil, empty, boundary values)
- [ ] Slow tests due to unnecessary database hits (use build_stubbed or mocks where appropriate)

PERFORMANCE:
- [ ] Loading entire tables into memory (use find_each/find_in_batches for large datasets)
- [ ] String operations in tight loops (use StringIO or array join)
- [ ] Missing caching for expensive computations or queries
- [ ] Serializing large objects unnecessarily

For each finding, report:
- File path and line number(s)
- Current code (brief snippet)
- Idiomatic alternative (brief snippet showing the better way)
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Why the idiomatic version is better (not just "convention" -- explain the concrete benefit)

Message me (the lead) with your complete findings. Mark your task as completed.
```

### For Go:

```
SCOPE: {files/directories}
LANGUAGE: Go

FILE CONTENTS:
{full contents of all files in scope}

You are the GO IDIOM SPECIALIST. Check every item:

- [ ] Not checking errors (ignored error returns)
- [ ] Error wrapping: using fmt.Errorf without %w, or not wrapping at all
- [ ] Naked returns in functions >5 lines
- [ ] Unnecessary use of pointers (value receivers where pointer is not needed)
- [ ] Not using table-driven tests
- [ ] Mutex when channel would be clearer (or vice versa)
- [ ] Interface pollution: defining interfaces with too many methods, or defining interfaces before they have multiple implementations
- [ ] Package naming: non-lowercase, stuttering (http.HTTPClient), utility packages (utils, helpers, common)
- [ ] init() functions with side effects
- [ ] Context not propagated through call chain
- [ ] Missing defer for resource cleanup
- [ ] Goroutine leaks (goroutines without shutdown mechanism)
- [ ] Bubble Tea View() methods with multiple switch/if blocks dispatching on the same state variable — consolidate into a single switch

For each finding, report file, line, current code, idiomatic alternative, severity, and concrete benefit.

Message me (the lead) with your complete findings. Mark your task as completed.
```

### For JavaScript/TypeScript:

```
SCOPE: {files/directories}
LANGUAGE: {JS or TS}

FILE CONTENTS:
{full contents of all files in scope}

You are the JS/TS IDIOM SPECIALIST. Check every item:

- [ ] var instead of const/let
- [ ] Callback hell instead of async/await or promises
- [ ] == instead of === (without intentional coercion)
- [ ] Missing error handling in async functions
- [ ] any types in TypeScript (should be narrowed)
- [ ] Mutation of function arguments or shared state
- [ ] Missing null/undefined checks where optional chaining (?.) would help
- [ ] Array methods misuse (forEach for mapping, manual loops for filtering)
- [ ] Barrel files re-exporting everything (tree-shaking issues)
- [ ] Missing type narrowing with discriminated unions
- [ ] Event listener leaks (addEventListener without removeEventListener)
- [ ] Synchronous operations that should be async (file I/O, network calls)

For each finding, report file, line, current code, idiomatic alternative, severity, and concrete benefit.

Message me (the lead) with your complete findings. Mark your task as completed.
```

For other languages, construct an equivalent checklist based on that language's established idioms and community standards.
