# Code Review Checklists

Detailed checklists for the reviewer agent in Phase 3.

## Security Checklist

- [ ] Injection flaws (SQL, command, LDAP, XPath)
- [ ] Authentication/authorization issues
- [ ] Sensitive data exposure (secrets, PII, credentials in code or logs)
- [ ] Input validation and sanitization
- [ ] Cross-site scripting (XSS) potential
- [ ] Insecure deserialization
- [ ] Known vulnerable dependencies added
- [ ] Error handling exposing internals (stack traces, DB info)
- [ ] Missing rate limiting where needed
- [ ] Insecure direct object references

## Architecture Checklist

- [ ] Single Responsibility Principle -- does each unit do one thing?
- [ ] Separation of concerns -- are layers/boundaries respected?
- [ ] Dependency direction -- depends on abstractions, not concretions?
- [ ] Coupling -- is it as loose as practical?
- [ ] Cohesion -- are related things grouped together?
- [ ] Consistency with existing codebase patterns
- [ ] Error handling strategy -- consistent with the rest of the project?
- [ ] Extensibility for likely future changes (but no speculative design)
- [ ] No circular dependencies introduced

## Clarity Checklist

- [ ] Function/method names clearly describe what they do
- [ ] Variable names are descriptive (no single-letter names except loops)
- [ ] Comments where logic is non-obvious (but no redundant comments)
- [ ] Public API documentation if applicable
- [ ] Cyclomatic complexity -- any function doing too much?
- [ ] Dead code or unreachable branches
- [ ] Magic numbers/strings that should be named constants
- [ ] Consistent code style with the rest of the codebase
- [ ] Log messages are useful and at appropriate levels
