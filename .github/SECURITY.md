# Security Policy

## Supported versions

This is a template, not a hosted service. The `main` branch is the only
supported version. If you've forked it, pull the latest `main` before
reporting.

## Reporting a vulnerability

**Do not open a public issue for a security problem.**

Use GitHub's [private vulnerability reporting](https://github.com/DLinacre/slime-factory-tycoon/security/advisories/new),
or contact the maintainer via [linacre.site](https://www.linacre.site).

Expect an acknowledgement within 7 days.

## What counts as a vulnerability here

This template's threat model is a **fully compromised client**. Assume the
attacker can call any RemoteEvent with any arguments at any rate. In scope:

- Any path where a client can grant itself currency, items, or multipliers
- Any duplication vector (cross-server, receipt replay, inventory)
- Any way to make another player lose data
- Any remote that skips validation or rate limiting
- Any DataStore pattern that can silently overwrite good data

Out of scope:

- "Exploiters can see client-side values" — by design; the client holds no truth
- Cosmetic/UI issues with no economic effect
- Rate limits being tunable — that's `GameConfig`, not a vulnerability

## Hardening already in place

See [SECURITY.md](SECURITY.md) for the full threat model: session-locked
DataStores, idempotent receipts, token-bucket click limiting, and declarative
per-remote validation.
