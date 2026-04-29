class ChildResponse {
  final String id;
  final String name;
  final String gender;
  final String dateOfBirth;

  ChildResponse({
    required this.id,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
  });

  factory ChildResponse.fromJson(Map<String, dynamic> json) {
    return ChildResponse(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      gender: json['gender'] ?? "",
      dateOfBirth: json['date_of_birth'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth,
    };
  }
}