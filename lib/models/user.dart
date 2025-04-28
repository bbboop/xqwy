class User {
  final String id;
  final String name;
  final String phone;
  final String avatar;
  double? height;
  double? weight;
  DateTime? birthdate;
  String? gender;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    this.height,
    this.weight,
    this.birthdate,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      avatar: json['avatar'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      birthdate:
          json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'height': height,
      'weight': weight,
      'birthdate': birthdate?.toIso8601String(),
      'gender': gender,
    };
  }
}
