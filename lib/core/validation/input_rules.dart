/// QUÉ SE PUEDE ESCRIBIR EN CADA CAMPO, en un solo sitio.
///
/// La app pedía correo, teléfono, documento, pesos, tensiones y colesteroles, y
/// cada pantalla decidía por su cuenta qué aceptaba. El resultado era desigual:
/// unos campos numéricos filtraban las teclas y otros sólo pedían el teclado
/// numérico —que en escritorio, en web y al pegar desde el portapapeles no
/// filtra nada—, y el correo no se comprobaba en ninguna parte: bastaba con que
/// no estuviera vacío, así que `perico` se guardaba como dirección de contacto.
///
/// Dos ideas separadas, y conviene no mezclarlas:
///
///  * **Los formateadores** ([decimal], [digits], [phone]) impiden TECLEAR lo
///    que no vale. Actúan mientras se escribe y también sobre lo que se pega.
///  * **Los validadores** ([isEmail]) comprueban al confirmar. Hacen falta
///    igualmente porque hay cosas que sólo se saben con el texto entero: un
///    correo se teclea carácter a carácter y está mal hasta el último.
library;

import 'package:flutter/services.dart';

/// Un correo con forma de correo.
///
/// No pretende decidir si la dirección EXISTE —eso sólo lo sabe quien envíe el
/// mensaje—, sino descartar lo que no puede ser una: sin arroba, sin dominio,
/// con espacios, o con un dominio sin punto. Exigir el punto deja fuera
/// direcciones internas legítimas del tipo `ana@servidor`, que en una app de
/// pacientes no se dan y en cambio son casi siempre un despiste al teclear.
final RegExp _emailPattern = RegExp(
  r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+"
  r'@'
  r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
  r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
);

abstract final class InputRules {
  /// ¿Tiene forma de correo? Un texto vacío devuelve `false`; que el campo sea
  /// obligatorio u opcional lo decide quien llama, no esta función.
  static bool isEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return false;
    // Un correo larguísimo no lo acepta ningún servidor y suele ser texto
    // pegado por error.
    if (text.length > 254) return false;
    return _emailPattern.hasMatch(text);
  }

  /// Sólo dígitos. Para cifras enteras: pulsaciones, tensión, kcal.
  static List<TextInputFormatter> digits({int? maxLength}) => [
    FilteringTextInputFormatter.digitsOnly,
    if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Un nombre de persona: letras y nada más que separe o una nombres.
  ///
  /// Deja pasar letras de cualquier alfabeto (`\p{L}` cubre tildes y la ñ),
  /// espacios, el guion de los compuestos («Anne-Marie») y el apóstrofo
  /// («O'Brien»). Fuera quedan los dígitos y los signos: un nombre no lleva `3`
  /// ni `@`, y colarlos suele ser un descuido al teclear o texto pegado por
  /// error. El límite ataja pegados larguísimos.
  static List<TextInputFormatter> name({int maxLength = 60}) => [
    FilteringTextInputFormatter.allow(RegExp(r"[\p{L} \-']", unicode: true)),
    LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Un correo mientras se escribe: sin espacios, ni al teclear ni al pegar.
  ///
  /// No comprueba la FORMA entera —de eso se encarga [isEmail] al confirmar—,
  /// sólo impide el error más común y silencioso: el espacio que el autocorrector
  /// del móvil o un copiar-pegar deja delante o en medio de la dirección. El
  /// tope de 254 es el máximo que acepta cualquier servidor.
  static List<TextInputFormatter> email({int maxLength = 254}) => [
    const _NoInteriorSpaceFormatter(),
    LengthLimitingTextInputFormatter(maxLength),
  ];

  /// El identificador de acceso, que puede ser documento O correo.
  ///
  /// Como no se sabe cuál de los dos es, no se restringe el juego de caracteres;
  /// pero ninguno de los dos lleva espacios, así que ésos se bloquean —al
  /// teclear y al pegar— y se pone un tope que corta pegados absurdos.
  static List<TextInputFormatter> identifier({int maxLength = 254}) => [
    const _NoInteriorSpaceFormatter(),
    LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Texto libre acotado: comentarios, notas, nombre del laboratorio.
  ///
  /// Aquí no se filtran caracteres —una observación clínica puede llevar
  /// «120/80», «#2» o «%»—, sólo se pone un techo para que un pegado accidental
  /// no meta miles de caracteres en la base.
  static List<TextInputFormatter> freeText({int maxLength = 500}) => [
    LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Nadie vive más de esto. El límite deja fuera fechas de nacimiento que sólo
  /// pueden ser un error de dedo (un `1800` por un `1980`).
  static const int maxHumanAgeYears = 120;

  /// La fecha de nacimiento más antigua admisible: hoy menos [maxHumanAgeYears].
  /// Se usa como `firstDate` del selector para que ni siquiera se pueda navegar
  /// más atrás. En un solo sitio, para que la regla no se desperdigue por las
  /// pantallas.
  static DateTime earliestBirthDate([DateTime? now]) {
    final ref = now ?? DateTime.now();
    return DateTime(ref.year - maxHumanAgeYears, ref.month, ref.day);
  }

  /// Un número con decimales y UN solo separador.
  ///
  /// El filtro que había antes era `RegExp(r'[0-9.,]')`, que deja teclear
  /// `1.2.3` y `70,,5`. Como después se hace `double.tryParse`, eso devolvía
  /// `null` y el valor se descartaba en silencio: el usuario escribía, pulsaba
  /// guardar y su dato no aparecía por ninguna parte, sin un solo mensaje.
  /// Aquí el segundo separador sencillamente no entra.
  static List<TextInputFormatter> decimal({
    int decimals = 2,
    int integerDigits = 4,
  }) => [_DecimalFormatter(decimals: decimals, integerDigits: integerDigits)];

  /// Teléfono: dígitos y los espacios con los que la gente agrupa las cifras.
  /// El prefijo internacional se elige aparte, así que aquí no cabe ni `+` ni
  /// paréntesis.
  static List<TextInputFormatter> phone({int maxLength = 15}) => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
    LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Documento de identidad: cifras y letras, sin espacios ni signos. Hay
  /// países que usan letra final (España) o alfanuméricos completos, así que
  /// restringirlo a dígitos dejaría fuera a usuarios reales.
  static List<TextInputFormatter> documentId({int maxLength = 20}) => [
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
    LengthLimitingTextInputFormatter(maxLength),
  ];

  /// Normaliza a punto decimal antes de `double.parse`. La coma es el
  /// separador natural en español, italiano, portugués y alemán, pero `parse`
  /// sólo entiende el punto.
  static double? toNumber(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
}

/// Deja escribir un número decimal bien formado y nada más.
class _DecimalFormatter extends TextInputFormatter {
  final int decimals;
  final int integerDigits;

  const _DecimalFormatter({
    required this.decimals,
    required this.integerDigits,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Se admiten las dos comas decimales; quién es cuál lo decide el idioma.
    final pattern = RegExp('^\\d{0,$integerDigits}([.,]\\d{0,$decimals})?\$');
    if (pattern.hasMatch(text)) return newValue;

    // Lo que no encaja no se escribe: se devuelve el texto anterior con su
    // cursor, que es cómo se comporta un campo que rechaza una tecla.
    return oldValue;
  }
}

/// Formateador de correo/identificador: recorta los espacios de los EXTREMOS
/// (los que deja el autocorrector del móvil o un copiar-pegar) pero RECHAZA la
/// edición si queda un espacio EN MEDIO —ni un correo ni un documento lo
/// llevan—, conservando el texto anterior.
///
/// Sustituye a `FilteringTextInputFormatter.deny(\s)`, que se limitaba a borrar
/// los espacios: eso podía pegar dos palabras (`ana ruiz` → `anaruiz`) en vez de
/// impedir la mezcla. Recortar los extremos y rechazar sólo el espacio interior
/// deja limpiar un pegado con espacios de sobra sin fabricar una dirección falsa.
class _NoInteriorSpaceFormatter extends TextInputFormatter {
  const _NoInteriorSpaceFormatter();

  static final RegExp _whitespace = RegExp(r'\s');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trimmed = newValue.text.trim();
    // Espacio interior (tras recortar los extremos): edición inválida, se
    // mantiene lo que había —igual que un campo que rechaza una tecla—.
    if (_whitespace.hasMatch(trimmed)) return oldValue;
    // Nada que recortar: se acepta tal cual (con su cursor).
    if (trimmed == newValue.text) return newValue;
    // Se recortaron espacios de los extremos: texto limpio, cursor al final.
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
}
