import 'package:arunika_app/data/models/request/consent_request.dart';

class SignUpRequest {
  final String name;
  final String phoneNumber;
  final String email;
  final String address;
  final String city;
  final String password;
  final ChildRequest child;

  /// What the parent agreed to. Null only for callers that predate consent.
  final ConsentRequest? consent;

  SignUpRequest({
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.city,
    required this.password,
    required this.child,
    this.consent,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "phone_number": phoneNumber,
    "email_address": email,
    "address": address,
    "city": city,
    "password": password,
    "child": [child.toJson()],
    if (consent != null) "consent": consent!.toJson(),
  };
}

class ChildRequest {
  final String name;
  final String gender;
  final String dateOfBirth;

  ChildRequest({
    required this.name,
    required this.gender,
    required this.dateOfBirth,
  });

  factory ChildRequest.fromJson(Map<String, dynamic> json) {
    return ChildRequest(
      name: json['name'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'gender': gender, 'date_of_birth': dateOfBirth};
  }
}
