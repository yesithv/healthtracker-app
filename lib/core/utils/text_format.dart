/// Convierte un nombre a "Title Case": primera letra de cada palabra en mayúscula
/// y el resto en minúscula. El legacy guarda nombres EN MAYÚSCULAS SOSTENIDAS
/// ("ROSALINA CASTILLO CUETO") y en la app deben verse "Rosalina Castillo Cueto".
/// Maneja acentos (toUpperCase/toLowerCase de Dart son Unicode-aware) y colapsa
/// espacios repetidos.
String toTitleCase(String? input) {
  if (input == null) return '';
  return input
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map(
        (w) => w.length == 1
            ? w.toUpperCase()
            : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}
