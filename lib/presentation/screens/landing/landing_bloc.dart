import 'package:arunika_app/presentation/screens/landing/landing_event.dart';
import 'package:arunika_app/presentation/screens/landing/landing_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LandingBloc extends Bloc<LandingEvent, LandingState> {
  LandingBloc() : super(LandingInitial()) {
    on<SignupButtonPressed>((event, emit) {
      emit(NavigateToSignUpPage());
    });
  }
}
