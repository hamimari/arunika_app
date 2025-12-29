import 'package:arunika_app/data/models/response/child_response.dart';

class UserResponse {
  final String id;
  final String name;
  final String phoneNumber;
  final String emailAddress;
  final String address;
  final String city;
  final List<ChildResponse> children;

  UserResponse({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.emailAddress,
    required this.address,
    required this.city,
    required this.children,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      emailAddress: json['email_address'],
      address: json['address'],
      city: json['city'],
      children: (json['children'] as List<dynamic>)
          .map((childJson) => ChildResponse.fromJson(childJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email_address': emailAddress,
      'address': address,
      'city': city,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}