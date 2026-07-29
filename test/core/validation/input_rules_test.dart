// Lo que se puede escribir en cada campo, comprobado.
//
// Dos bloques, que corresponden a las dos mitades del problema: lo que el campo
// no deja TECLEAR (formateadores) y lo que se rechaza al CONFIRMAR (validadores).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/validation/input_rules.dart';

/// Simula teclear/pegar [next] cuando el campo ya contenía [previous], y
/// devuelve lo que queda escrito. Es lo mismo que hace Flutter al aplicar la
/// cadena de formateadores.
String type(
  List<TextInputFormatter> formatters,
  String next, {
  String previous = '',
}) {
  var value = TextEditingValue(
    text: previous,
    selection: TextSelection.collapsed(offset: previous.length),
  );
  final incoming = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(offset: next.length),
  );
  var result = incoming;
  for (final f in formatters) {
    result = f.formatEditUpdate(value, result);
  }
  return result.text;
}

void main() {
  group('Correo', () {
    test('acepta direcciones normales', () {
      for (final ok in const [
        'ana@ejemplo.com',
        'ana.perez@hospital.gov.co',
        "o'neill+citas@clinica.es",
        'ANA@EJEMPLO.COM',
        '  ana@ejemplo.com  ', // los espacios de sobra se recortan
      ]) {
        expect(InputRules.isEmail(ok), isTrue, reason: '$ok debería valer');
      }
    });

    test('rechaza lo que no puede ser una dirección', () {
      for (final bad in const [
        '', // vacío
        'perico', // el caso real: se guardaba tal cual
        'perico@', // sin dominio
        '@ejemplo.com', // sin buzón
        'ana@servidor', // dominio sin punto
        'ana ruiz@ejemplo.com', // con espacio
        'ana@ejemplo..com', // punto doble
        'ana@-ejemplo.com', // dominio que empieza por guion
        'ana@ejemplo.com.', // punto final
      ]) {
        expect(
          InputRules.isEmail(bad),
          isFalse,
          reason: '«$bad» no debería valer',
        );
      }
    });

    test('rechaza un correo absurdamente largo', () {
      expect(InputRules.isEmail('${'a' * 250}@ejemplo.com'), isFalse);
    });

    test('un nulo no revienta', () {
      expect(InputRules.isEmail(null), isFalse);
    });
  });

  group('Campos numéricos', () {
    test('el decimal no deja meter letras ni signos', () {
      final f = InputRules.decimal();
      expect(type(f, '70'), '70');
      expect(type(f, '70a', previous: '70'), '70');
      expect(type(f, '-70'), '');
      expect(type(f, '70kg', previous: '70'), '70');
    });

    test('acepta punto y coma, porque el idioma decide cuál', () {
      final f = InputRules.decimal(decimals: 1);
      expect(type(f, '70.5'), '70.5');
      expect(type(f, '70,5'), '70,5');
    });

    test('un SEGUNDO separador no entra', () {
      // Éste era el defecto de verdad: el filtro viejo, `RegExp('[0-9.,]')`,
      // dejaba escribir `1.2.3`; después `double.tryParse` devolvía null y el
      // dato se perdía en silencio, sin un solo mensaje.
      final f = InputRules.decimal();
      expect(type(f, '70.5.', previous: '70.5'), '70.5');
      expect(type(f, '70,,', previous: '70,'), '70,');
      expect(type(f, '1.2.3'), '');
    });

    test('respeta el número de decimales y de enteros', () {
      final f = InputRules.decimal(decimals: 1, integerDigits: 3);
      expect(type(f, '175.5'), '175.5');
      expect(type(f, '175.55', previous: '175.5'), '175.5');
      expect(type(f, '1755', previous: '175'), '175');
    });

    test('deja borrar del todo', () {
      final f = InputRules.decimal();
      expect(type(f, '', previous: '70'), '');
      expect(type(f, '70.', previous: '70'), '70.');
    });

    test('los enteros son sólo dígitos', () {
      final f = InputRules.digits(maxLength: 3);
      expect(type(f, '120'), '120');
      expect(type(f, '12.0'), '120');
      expect(type(f, 'abc'), '');
      expect(type(f, '1204'), '120');
    });

    test('pegar basura desde el portapapeles tampoco cuela', () {
      // El teclado numérico del móvil es una sugerencia, no un filtro: en
      // escritorio, en web y al pegar entra cualquier cosa.
      expect(type(InputRules.digits(), 'tensión 120'), '120');
      expect(type(InputRules.decimal(), '70,5 kg'), '');
    });
  });

  group('Teléfono y documento', () {
    test('el teléfono admite cifras y espacios, nada más', () {
      final f = InputRules.phone();
      expect(type(f, '300 123 4567'), '300 123 4567');
      expect(type(f, '+57 300', previous: ''), '57 300');
      expect(type(f, 'llámame'), '');
    });

    test('el documento admite letras, porque hay países que las usan', () {
      final f = InputRules.documentId();
      expect(type(f, '12345678Z'), '12345678Z');
      expect(type(f, '1.234.567'), '1234567');
      expect(type(f, '12 34'), '1234');
    });
  });

  group('Lectura del número', () {
    test('entiende la coma decimal', () {
      expect(InputRules.toNumber('70,5'), 70.5);
      expect(InputRules.toNumber('70.5'), 70.5);
      expect(InputRules.toNumber(' 70 '), 70);
    });

    test('devuelve null en vez de inventarse un valor', () {
      expect(InputRules.toNumber(''), isNull);
      expect(InputRules.toNumber('abc'), isNull);
      expect(InputRules.toNumber('1.2.3'), isNull);
    });
  });
}
