## ADDED Requirements

### Requirement: Environment-based backend configuration
The backend SHALL load all environment-specific configuration (database URL, API keys, ports, secrets) from environment variables or a `.env` file, with no hard-coded values in source code.

#### Scenario: Server starts with environment variables set
- **WHEN** the required environment variables are present at startup
- **THEN** the server binds to the configured port and connects to the configured database

#### Scenario: Server fails fast on missing required config
- **WHEN** a required environment variable is absent at startup
- **THEN** the server logs a clear error message and exits with a non-zero code

### Requirement: Input validation on all API endpoints
Every API endpoint SHALL validate incoming request bodies and parameters, rejecting invalid input with a `400 Bad Request` response before any business logic executes.

#### Scenario: Valid request passes validation
- **WHEN** a request with valid body and parameters is received
- **THEN** the request proceeds to business logic

#### Scenario: Invalid request rejected with 400
- **WHEN** a request is missing required fields or contains invalid values
- **THEN** the server responds with HTTP 400 and a descriptive error body

### Requirement: Centralised error handling middleware
The backend SHALL have a single error-handling middleware/interceptor that catches all unhandled exceptions and returns a consistent JSON error response without leaking stack traces to clients.

#### Scenario: Unhandled exception returns 500
- **WHEN** a route handler throws an unhandled exception
- **THEN** the middleware returns HTTP 500 with a generic JSON error body and logs the full error internally

#### Scenario: Known business error returns appropriate status
- **WHEN** a route handler throws a typed application error (e.g. NotFoundError)
- **THEN** the middleware returns the corresponding HTTP status code and structured error body

### Requirement: Security headers on all responses
The backend SHALL include standard security headers (e.g. `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`) on all HTTP responses.

#### Scenario: Security headers present in response
- **WHEN** any API endpoint is called
- **THEN** the response includes at minimum `X-Content-Type-Options: nosniff` and `X-Frame-Options: DENY`

### Requirement: Structured JSON logging
The backend SHALL emit structured JSON log entries with timestamp, level, message, and context so that logs are machine-parseable.

#### Scenario: Request logged on completion
- **WHEN** an API request completes
- **THEN** a structured JSON log entry with method, path, status code, and duration is written
