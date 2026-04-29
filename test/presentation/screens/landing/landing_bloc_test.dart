import 'package:arunika_app/presentation/screens/landing/landing_bloc.dart';
import 'package:arunika_app/presentation/screens/landing/landing_event.dart';
import 'package:arunika_app/presentation/screens/landing/landing_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LandingBloc', () {
    test('initial state is LandingInitial', () {
      final bloc = LandingBloc();
      expect(bloc.state, isA<LandingInitial>());
      bloc.close();
    });

    blocTest<LandingBloc, LandingState>(
      'SignupButtonPressed emits NavigateToSignUpPage',
      build: LandingBloc.new,
      act: (b) => b.add(SignupButtonPressed()),
      expect: () => [isA<NavigateToSignUpPage>()],
    );
  });
}
