class UpdateUserRequest {
  final String id;
  final String name;
  final String phoneNumber;
  final String emailAddress;
  final String address;
  final String city;
  final List<UpdateChildRequest> child;

  UpdateUserRequest({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.emailAddress,
    required this.address,
    required this.city,
    required this.child,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email_address': emailAddress,
      'address': address,
      'city': city,
      'child': child.map((c) => c.toJson()).toList(),
    };
  }
}

class UpdateChildRequest {
  final String id;
  final String name;
  final String gender;
  final String birthDate;

  UpdateChildRequest({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'date_of_birth': birthDate,
    };
  }
}