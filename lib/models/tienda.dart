class Tienda {
  final String id;
  final String name;
  final String? address;
  final int userCount;
  final String createdAt;

  const Tienda({
    required this.id,
    required this.name,
    this.address,
    required this.userCount,
    required this.createdAt,
  });

  factory Tienda.fromJson(Map<String, dynamic> json) => Tienda(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        userCount: json['user_count'] ?? 0,
        createdAt: json['created_at'] ?? '',
      );
}
