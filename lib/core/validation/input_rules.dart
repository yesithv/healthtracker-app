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
