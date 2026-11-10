# Security Policy

IUB PAY V1 is a student prototype and is **not approved for
production use**. It uses a mock payment gateway, contains development
defaults, and has known limitations documented in the
[README](README.md#known-limitations). Do not connect it to real payment
providers or deploy it with real personal or financial data.

## Supported versions

This project does not currently maintain multiple release branches. Security
fixes are applied to the current default branch when practical.

## Reporting a vulnerability

Please do **not** open a public issue for an undisclosed vulnerability and do
not include secrets, personal data, or payment information in a report.

If GitHub's private vulnerability reporting or Security Advisories are enabled
for this repository, use that private channel. Otherwise, contact the project
maintainers privately through the repository's owner or course/project
supervisor and include:

- a clear description of the vulnerability and its potential impact;
- the affected file, endpoint, component, or configuration;
- reproducible steps or a minimal proof of concept;
- the versions, commit, or environment where it was observed; and
- any suggested mitigation.

For reports involving an active deployment, immediately include the deployment
owner so credentials, tokens, and exposed services can be rotated or disabled.

## What to expect

Maintainers will acknowledge a report when they can, investigate its
reproducibility and impact, and coordinate a fix or mitigation. Please allow
time for validation before publicly disclosing the issue. Reports may be
published in sanitized form after a fix, without exposing reporter identity or
sensitive details.

This is a volunteer/coursework project, so response and remediation timelines
are not guaranteed.

## Security expectations for development

- Never commit `.env` files, JWT secrets, webhook tokens, passwords, API keys,
  database credentials, or private certificates.
- Use only the clearly labelled seeded test accounts and mock payment flows.
- Set strong, unique secrets and restrict CORS before any non-local
  deployment. Development defaults are not production-safe.
- Treat all client input, prices, payment results, and webhook payloads as
  untrusted until validated by the backend.
- Do not add logging that exposes passwords, bearer tokens, webhook secrets,
  personal data, or payment details.
- Keep dependencies and database migrations reviewable, and mention security
  implications in pull requests that change authentication, authorization,
  payments, data access, or deployment configuration.

## Scope

Reports are in scope when they affect the repository's code, configuration, or
documented deployment instructions, including:

- authentication, authorization, tenant isolation, or session handling;
- payment, refund, webhook, idempotency, ledger, or audit logic;
- exposure of secrets or sensitive data;
- injection, unsafe deserialization, or other remotely exploitable behavior;
- insecure Docker, CORS, or deployment configuration.

Social engineering, denial-of-service against third-party infrastructure,
issues in dependencies without a project-specific impact, and vulnerabilities
requiring real credentials or production infrastructure are generally out of
scope. They may still be reported privately for assessment.
