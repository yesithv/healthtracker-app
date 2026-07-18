/// Un laboratorio del catálogo (GET /api/v1/labs), para el selector de la app.
class Lab {
  final String code;
  final String name;
  final String? city;

  const Lab({required this.code, required this.name, this.city});

  factory Lab.fromJson(Map<String, dynamic> json) => Lab(
        code: json['code'] as String,
        name: json['name'] as String,
        city: json['city'] as String?,
      );
}
