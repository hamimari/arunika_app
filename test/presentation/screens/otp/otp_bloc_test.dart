import 'package:arunika_app/presentation/screens/otp/otp_bloc.dart';
import 'package:arunika_app/presentation/screens/otp/otp_event.dart';
import 'package:arunika_app/presentation/screens/otp/otp_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtpBloc', () {
    test('initial state is OtpInitial', () {
      final bloc = OtpBloc();
      expect(bloc.state, isA<OtpInitial>());
      bloc.close();
    });

    blocTest<OtpBloc, OtpState>(
      'VerifyButtonPressed emits NavigateToChildRegistrationPage',
      build: OtpBloc.new,
      act: (b) => b.add(VerifyButtonPressed()),
      expect: () => [isA<NavigateToChildRegistrationPage>()],
    );
  });
}
