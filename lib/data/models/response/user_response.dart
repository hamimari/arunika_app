import 'package:arunika_app/data/models/response/child_response.dart';
import 'package:arunika_app/data/models/response/subscription_info.dart';

class UserResponse {
  final String id;
  final String name;
  final String phoneNumber;
  final String emailAddress;
  final String address;
  final String city;
  final List<ChildResponse> children;
  final bool isSubscribed;
  final SubscriptionInfo? subscription;
  /// Whether the account holder has proven control of [emailAddress].
  /// Gates password recovery only — never content or purchases.
  final bool emailVerified;

  UserResponse({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.emailAddress,
    required this.address,
    required this.city,
    required this.children,
    this.isSubscribed = false,
    this.subscription,
    this.emailVerified = true,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      emailAddress: json['email_address'],
      address: json['address'],
      city: json['city'],
      children:
          (json['children'] as List<dynamic>?)
              ?.map((childJson) => ChildResponse.fromJson(childJson))
              .toList() ??
          [],
      isSubscribed: json['is_subscribed'] as bool? ?? false,
      subscription: json['subscription'] != null
          ? SubscriptionInfo.fromJson(json['subscription'] as Map<String, dynamic>)
          : null,
      // Defaults to true so a profile from a backend that predates the field
      // never shows the verification prompt to an existing user.
      emailVerified: json['email_verified'] as bool? ?? true,
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
      'is_subscribed': isSubscribed,
      'subscription': subscription?.toJson(),
      'email_verified': emailVerified,
    };
  }
}
