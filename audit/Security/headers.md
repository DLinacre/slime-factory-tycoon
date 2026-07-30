# Security Headers — Measured

Command: `curl -sI -L https://www.linacre.site/games`

## Current state — strong

| Header | Value | Grade |
|---|---|---|
| `content-security-policy` | `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' fonts.googleapis.com; img-src 'self' data: ...; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; upgrade-insecure-requests` | A− |
| `strict-transport-security` | `max-age=63072000; includeSubDomains; preload` | A+ |
| `x-frame-options` | `DENY` | A |
| `x-content-type-options` | `nosniff` | A |
| `referrer-policy` | `strict-origin-when-cross-origin` | A |
| `permissions-policy` | `camera=(), microphone=(), geolocation=(), payment=(), usb=(), magnetometer=(), gyroscope=(), interest-cohort=()` | A+ |
| `cross-origin-opener-policy` | `same-origin` | A |
| `cross-origin-resource-policy` | `same-origin` | A |

This exceeds typical commercial practice. `frame-ancestors 'none'` plus
`X-Frame-Options: DENY` is correct belt-and-braces clickjacking defence, and
`interest-cohort=()` is a privacy detail almost nobody sets.

## The one weakness

`style-src` allows `'unsafe-inline'`. This is the standard concession for
CSS-in-JS and Tailwind's runtime styles, but it does weaken CSS-injection
defence.

**Recommendation (medium priority, non-trivial):** move to nonce-based styles.

```js
// vercel.json — requires generating a nonce per request via middleware
"style-src 'self' 'nonce-{NONCE}' https://fonts.googleapis.com"
```

## Recommended addition — CSP reporting

Currently there is no way to know if the CSP is breaking things in the wild.

```json
{
  "key": "Content-Security-Policy-Report-Only",
  "value": "default-src 'self'; report-uri /api/csp-report; report-to csp-endpoint"
}
```

```json
{
  "key": "Reporting-Endpoints",
  "value": "csp-endpoint=\"https://www.linacre.site/api/csp-report\""
}
```

## Recommended addition — Dependabot

No dependency scanning is configured. Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    groups:
      minor-and-patch:
        update-types: ["minor", "patch"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
```

Grouping minor/patch updates avoids PR spam while still surfacing majors.
