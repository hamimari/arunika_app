class ChildResponse {
  final String id;
  final String name;
  final String gender;
  final String dateOfBirth;
  final int starPoints;

  ChildResponse({
    required this.id,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    this.starPoints = 0,
  });

  factory ChildResponse.fromJson(Map<String, dynamic> json) {
    return ChildResponse(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      gender: json['gender'] ?? "",
      dateOfBirth: json['date_of_birth'] ?? "",
      starPoints: (json['star_points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'star_points': starPoints,
    };
  }
}
