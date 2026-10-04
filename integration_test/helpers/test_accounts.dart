/// Generates a fresh, unique registration payload per call.
///
/// Every flow signs up its own account rather than sharing one — the backend
/// enforces unique email/phone, and a shared account would make one test's
/// leftover state (an entitlement, a subscription) leak into another's
/// assertions.
class TestAccount {
  TestAccount() : suffix = DateTime.now().microsecondsSinceEpoch.toString();

  final String suffix;

  String get name => 'Integration Test $suffix';
  String get email => 'itest-$suffix@example.test';
  String get phone => '0812${suffix.substring(suffix.length - 8)}';
  String get password => 'secret123';
  String get childName => 'Anak $suffix';
}
