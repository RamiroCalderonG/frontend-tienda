class User {
  final String id;
  final String storeId;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  const User({
    required this.id,
    required this.storeId,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        storeId: json['store_id'],
        name: json['name'],
        email: json['email'],
        role: json['role'],
        isActive: json['is_active'],
      );

  bool get isAdmin => role == 'admin';
}
