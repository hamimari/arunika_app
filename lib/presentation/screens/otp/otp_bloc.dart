import 'package:arunika_app/presentation/screens/otp/otp_event.dart';
import 'package:arunika_app/presentation/screens/otp/otp_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc() : super(OtpInitial()) {
    on<VerifyButtonPressed>((event, emit) {
      emit(NavigateToChildRegistrationPage());
    });
  }
}
