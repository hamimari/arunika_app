## ADDED Requirements

### Requirement: Security headers and CSP on every backoffice response
The backoffice web server SHALL send `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options` and `Referrer-Policy` on every response, including static assets and the SPA fallback. The CSP SHALL restrict scripts to the same origin, restrict `connect-src` to the same origin and the configured API origin, and forbid framing and plugins.

#### Scenario: Static asset keeps security headers
- **WHEN** a fingerprinted JavaScript or CSS asset is requested
- **THEN** the response includes all four security headers alongside its cache headers

#### Scenario: SPA route carries the CSP
- **WHEN** any application route is requested and `index.html` is served
- **THEN** the response includes a `Content-Security-Policy` with `frame-ancestors 'none'` and `object-src 'none'`

#### Scenario: CSP does not break the application
- **WHEN** the backoffice Playwright E2E suite runs against the production Docker image
- **THEN** it passes with no CSP violations reported in the browser console
