/// In-memory, session-scoped flag for the parental gate (see
/// ParentalGateGuard). A child-directed app must not let a purchase screen
/// open without an adult confirming a simple challenge first — but once
/// confirmed, re-prompting on every navigation within the same app session
/// would just be friction. Resetting is automatic: this is a plain static
/// field, so it goes back to false the moment the process restarts.
class ParentalGateSession {
  ParentalGateSession._();

  static bool passed = false;
}
