import 'package:arunika_app/data/models/response/child_response.dart';

class SignUpResponse {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String address;
  final String city;
  final String token;
  final String refreshToken;
  final List<ChildResponse> children;

  SignUpResponse({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.city,
    required this.token,
    required this.refreshToken,
    required this.children
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    final data = json["data"] ?? {};

    return SignUpResponse(
      id: data["id"] ?? "",
      name: data["name"] ?? "",
      phoneNumber: data["phone_number"] ?? "",
      email: data["email"] ?? "",
      address: data["address"] ?? "",
      city: data["city"] ?? "",
      token: data["token"] ?? "",
      refreshToken: data["refresh_token"] ?? "",
      children: (data["child"] as List<dynamic>? ?? [])
          .map((childJson) => ChildResponse.fromJson(childJson))
          .toList(),
    );
  }

}

class Child {
  final String id;
  final String name;
  final String gender;
  final String birthDate;

  Child({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "gender": gender,
    "date_of_birth": birthDate
  };

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      gender: json["gender"] ?? "",
      birthDate: json["birthDate"] ?? "",
    );
  }
}

