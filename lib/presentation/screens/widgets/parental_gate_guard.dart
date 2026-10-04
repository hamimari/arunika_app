import 'package:arunika_app/core/utils/parental_gate_session.dart';
import 'package:arunika_app/presentation/screens/widgets/parental_gate_screen.dart';
import 'package:flutter/material.dart';

/// Wraps a route's content so it only renders once the parental gate has
/// been passed this app session — see ParentalGateSession. Apply this at
/// every route entry point that starts a purchase (currently `/premium`
/// and `/payment`).
class ParentalGateGuard extends StatefulWidget {
  final Widget child;

  const ParentalGateGuard({super.key, required this.child});

  @override
  State<ParentalGateGuard> createState() => _ParentalGateGuardState();
}

class _ParentalGateGuardState extends State<ParentalGateGuard> {
  @override
  Widget build(BuildContext context) {
    if (ParentalGateSession.passed) {
      return widget.child;
    }
    return ParentalGateScreen(
      onPassed: () => setState(() => ParentalGateSession.passed = true),
    );
  }
}
