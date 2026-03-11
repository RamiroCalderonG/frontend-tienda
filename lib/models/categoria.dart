class Categoria {
  final String id;
  final String storeId;
  final String nombre;

  const Categoria({
    required this.id,
    required this.storeId,
    required this.nombre,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        storeId: json['store_id'],
        nombre: json['nombre'],
      );
}
