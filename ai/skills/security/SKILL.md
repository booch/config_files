---
name: security
description: Security guidelines for secure coding and code review. This skill should be used when architecting/designing systems, writing code, or reviewing code.
---

# Security

This skill provides guidance on writing secure code and identifying security vulnerabilities during code review.

## Core Principles

- **Defense in Depth**: Layer multiple security controls; don't rely on a single defense
- **Least Privilege**: Grant minimum permissions necessary for functionality
- **Don't Trust Input**: Validate and sanitize all external input
- **Keep It Simple**: Complex code is harder to secure
- **Fail Secure**: When errors occur, fail closed rather than open

## OWASP Top 10 (2025)

The OWASP Top 10 represents the most critical web application security risks.

### A01: Broken Access Control

Failures in enforcing what authenticated users are allowed to do.

**Vulnerabilities:**

- Missing access control checks on sensitive operations
- Insecure Direct Object References (IDOR) — accessing resources by ID without authorization checks
- Privilege escalation — users accessing admin functionality
- CORS misconfiguration allowing unauthorized API access
- Bypassing access control by modifying URLs, parameters, or JWT tokens

**Prevention:**

- Deny by default; explicitly grant access
- Implement access control checks server-side, not client-side
- Use consistent access control mechanisms throughout the application
- Log access control failures and alert on repeated failures
- Invalidate sessions on logout and set appropriate timeouts

### A02: Security Misconfiguration

Insecure default configurations, incomplete setups, or misconfigured security settings.

**Vulnerabilities:**

- Default credentials left unchanged
- Unnecessary features enabled (ports, services, pages, accounts)
- Error messages exposing sensitive information (stack traces, database errors)
- Missing security headers
- Outdated or vulnerable software configurations

**Prevention:**

- Automate secure configuration deployment
- Remove unused features and dependencies
- Review cloud storage permissions (S3 buckets, etc.)
- Send security directives via headers (CSP, X-Content-Type-Options, etc.)
- Use different credentials across environments

### A03: Software Supply Chain Failures

Vulnerabilities introduced through dependencies, build systems, or distribution infrastructure.

**Vulnerabilities:**

- Using components with known vulnerabilities
- Outdated or unmaintained dependencies
- Not verifying package integrity
- Typosquatting attacks (malicious packages with similar names)
- Compromised build pipelines

**Prevention:**

- Maintain inventory of all dependencies and their versions
- Continuously monitor for vulnerabilities (Dependabot, Snyk, etc.)
- Only obtain packages from official sources
- Verify package signatures and checksums
- Review dependency changes in pull requests
- Use lock files to pin dependency versions

### A04: Cryptographic Failures

Failures related to cryptography that expose sensitive data.

**Vulnerabilities:**

- Transmitting data in cleartext (HTTP, FTP, SMTP)
- Using weak or deprecated algorithms (MD5, SHA1, DES)
- Weak or default cryptographic keys
- Not enforcing encryption (missing TLS, weak TLS configuration)
- Improper key management (hardcoded keys, keys in source control)

**Prevention:**

- Encrypt all sensitive data in transit and at rest
- Use strong, current algorithms (AES-256, RSA-2048+, SHA-256+)
- Generate keys using cryptographically secure random generators
- Store keys securely, separate from encrypted data
- Use TLS 1.2+ with strong cipher suites
- Never implement custom cryptography

### A05: Injection

Untrusted data sent to an interpreter as part of a command or query.

**Vulnerabilities:**

- SQL Injection — malicious SQL in user input
- NoSQL Injection — malicious queries in document databases
- OS Command Injection — shell commands in user input
- LDAP Injection — malicious LDAP queries
- Cross-Site Scripting (XSS) — malicious scripts in web pages

**Prevention:**

- Use parameterized queries or prepared statements (never string concatenation)
- Use ORM frameworks correctly
- Validate and sanitize all input (allowlist preferred over denylist)
- Escape output appropriate to context (HTML, JavaScript, SQL, etc.)
- Use Content Security Policy (CSP) headers
- Apply least privilege to database accounts

### A06: Insecure Design

Security flaws from missing or ineffective security controls in the design phase.

**Vulnerabilities:**

- Missing threat modeling
- No rate limiting on expensive operations
- Missing input validation requirements
- Inadequate segregation of duties
- Business logic flaws

**Prevention:**

- Establish secure development lifecycle
- Use threat modeling for critical features
- Define security requirements and acceptance criteria
- Use secure design patterns and reference architectures
- Integrate security testing into CI/CD

### A07: Authentication Failures

Failures in authentication mechanisms.

**Vulnerabilities:**

- Credential stuffing (using breached username/password lists)
- Brute force attacks (no rate limiting)
- Permitting weak passwords
- Missing or ineffective multi-factor authentication
- Session fixation or improper session invalidation
- Exposing session IDs in URLs

**Prevention:**

- Delegate authentication to trusted 3rd parties
- Implement multi-factor authentication
- Enforce strong password policies
- Rate limit and lock out after failed attempts
- Use secure session management (regenerate IDs on login)
- Never ship with default credentials
- Use secure (slow) password hashing (bcrypt, Argon2, scrypt)

### A08: Data Integrity Failures

Failures to protect data and code from unauthorized modification.

**Vulnerabilities:**

- Insecure deserialization — untrusted data deserialized without validation
- Missing integrity checks on software updates
- Unsigned or unverified CI/CD pipelines
- Trusting serialized objects from untrusted sources

**Prevention:**

- Use digital signatures to verify integrity
- Validate all serialized data from untrusted sources
- Implement integrity checks in CI/CD pipelines
- Review code and configuration changes
- Avoid serializing sensitive data

### A09: Security Logging and Alerting Failures

Insufficient logging, monitoring, and alerting.

**Vulnerabilities:**

- Not logging security-relevant events
- Logs not containing enough detail for forensics
- No monitoring or alerting on suspicious activity
- Logs stored only locally, vulnerable to tampering
- Missing audit trails for sensitive operations

**Prevention:**

- Log all authentication attempts (success and failure)
- Log all access control failures
- Log all input validation failures
- Include context: who, what, when, where
- Store logs centrally, append-only
- Implement real-time alerting for critical events

### A10: Mishandling of Exceptional Conditions

Improper error handling that leads to security vulnerabilities.

**Vulnerabilities:**

- Failing open instead of closed
- Exposing sensitive information in error messages
- Resource exhaustion from unhandled exceptions
- Logic errors from unexpected states
- Race conditions and time-of-check/time-of-use (TOCTOU) bugs

**Prevention:**

- Catch and handle all exceptions appropriately
- Fail secure — deny access on error
- Use generic error messages for users; log details server-side
- Test error handling paths explicitly
- Use timeouts and circuit breakers

## Language-Specific Guidelines

### Ruby / Rails

- Use `strong_parameters` to whitelist permitted attributes
- Use parameterized queries (ActiveRecord does this by default, but beware of raw SQL)
- Enable CSRF protection (on by default in Rails)
- Use `html_safe` sparingly and never on user input
- Use `SecureRandom` for tokens, not `rand`
- Set `config.force_ssl = true` in production
- Use Brakeman for static security analysis

### JavaScript / Node.js

- Avoid `eval()` and `Function()` constructor with user input
- Use parameterized queries with database drivers
- Sanitize HTML with libraries like DOMPurify
- Use `helmet` middleware for security headers
- Validate JSON schemas for API input
- Use `npm audit` or `yarn audit` regularly
- Be cautious with `dangerouslySetInnerHTML` in React

### Bash

- Quote all variables: `"$var"` not `$var`
- Never use `eval` with user input
- Avoid command substitution with untrusted data
- Use `--` to separate options from arguments
- Validate and sanitize all input before use
- Use arrays for command arguments to avoid injection

## Security Review Checklist

When reviewing code for security:

- [ ] Are all inputs validated and sanitized?
- [ ] Are parameterized queries used for database access?
- [ ] Is output properly escaped for its context?
- [ ] Are authentication and authorization checks in place?
- [ ] Is sensitive data encrypted in transit and at rest?
- [ ] Are errors handled without exposing sensitive information?
- [ ] Are dependencies up to date and free of known vulnerabilities?
- [ ] Is logging sufficient for security monitoring?
- [ ] Are security headers configured correctly?
- [ ] Is rate limiting in place for sensitive operations?
