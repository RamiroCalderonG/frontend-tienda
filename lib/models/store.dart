class Store {
  final String id;
  final String name;
  final String? address;
  final Map<String, dynamic> config;

  const Store({
    required this.id,
    required this.name,
    this.address,
    required this.config,
  });

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        config: Map<String, dynamic>.from(json['config'] ?? {}),
      );
}
