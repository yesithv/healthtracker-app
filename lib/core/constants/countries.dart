import 'dart:ui' show PlatformDispatcher;

/// País del catálogo (espejo de `ref.country` del backend, sembrado en V26).
/// [iso] es ISO 3166-1 alpha-2 — es lo que viaja en `country` al registrar —
/// y [dialCode] el prefijo E.164 para componer el teléfono completo (WhatsApp).
class Country {
  final String iso;
  final String name;
  final String dialCode;

  const Country(this.iso, this.name, this.dialCode);

  /// Bandera emoji derivada del ISO (regional indicator symbols): sin assets.
  String get flag => String.fromCharCodes(iso.codeUnits.map((c) => c + 127397));
}

/// Catálogo local de países. Vive embebido (la app es local-first y esto cambia
/// casi nunca); el backend valida contra su propia copia y descarta lo que no
/// reconozca, así que ambos lados pueden evolucionar sin romperse.
class Countries {
  Countries._();

  /// Ordenados alfabéticamente por nombre (es el orden del picker).
  static const List<Country> all = [
    Country('DE', 'Alemania', '+49'),
    Country('AR', 'Argentina', '+54'),
    Country('AU', 'Australia', '+61'),
    Country('AT', 'Austria', '+43'),
    Country('BE', 'Bélgica', '+32'),
    Country('BO', 'Bolivia', '+591'),
    Country('BR', 'Brasil', '+55'),
    Country('CA', 'Canadá', '+1'),
    Country('CL', 'Chile', '+56'),
    Country('CN', 'China', '+86'),
    Country('CO', 'Colombia', '+57'),
    Country('KR', 'Corea del Sur', '+82'),
    Country('CR', 'Costa Rica', '+506'),
    Country('CU', 'Cuba', '+53'),
    Country('DK', 'Dinamarca', '+45'),
    Country('EC', 'Ecuador', '+593'),
    Country('SV', 'El Salvador', '+503'),
    Country('AE', 'Emiratos Árabes Unidos', '+971'),
    Country('ES', 'España', '+34'),
    Country('US', 'Estados Unidos', '+1'),
    Country('FR', 'Francia', '+33'),
    Country('GT', 'Guatemala', '+502'),
    Country('HN', 'Honduras', '+504'),
    Country('IN', 'India', '+91'),
    Country('IE', 'Irlanda', '+353'),
    Country('IL', 'Israel', '+972'),
    Country('IT', 'Italia', '+39'),
    Country('JP', 'Japón', '+81'),
    Country('MX', 'México', '+52'),
    Country('NI', 'Nicaragua', '+505'),
    Country('NO', 'Noruega', '+47'),
    Country('NZ', 'Nueva Zelanda', '+64'),
    Country('NL', 'Países Bajos', '+31'),
    Country('PA', 'Panamá', '+507'),
    Country('PY', 'Paraguay', '+595'),
    Country('PE', 'Perú', '+51'),
    Country('PL', 'Polonia', '+48'),
    Country('PT', 'Portugal', '+351'),
    Country('PR', 'Puerto Rico', '+1'),
    Country('GB', 'Reino Unido', '+44'),
    Country('DO', 'República Dominicana', '+1'),
    Country('ZA', 'Sudáfrica', '+27'),
    Country('SE', 'Suecia', '+46'),
    Country('CH', 'Suiza', '+41'),
    Country('TR', 'Turquía', '+90'),
    Country('UY', 'Uruguay', '+598'),
    Country('VE', 'Venezuela', '+58'),
  ];

  static Country? byIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final upper = iso.toUpperCase();
    for (final c in all) {
      if (c.iso == upper) return c;
    }
    return null;
  }

  /// País por defecto SIN preguntar: el del locale del dispositivo si está en
  /// el catálogo; si no, Colombia (mercado principal). Es la captura silenciosa:
  /// el usuario solo lo toca si el default no le aplica.
  static Country deviceDefault() {
    final iso = PlatformDispatcher.instance.locale.countryCode;
    return byIso(iso) ?? byIso('CO')!;
  }
}
