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
  final value = TextEditingValue(
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

  group('Nombre', () {
    test('acepta letras con tildes, ñ, guion y apóstrofo', () {
      final f = InputRules.name();
      expect(type(f, 'José Ñáñez'), 'José Ñáñez');
      expect(type(f, 'Anne-Marie'), 'Anne-Marie');
      expect(type(f, "O'Brien"), "O'Brien");
      expect(type(f, 'María del Carmen'), 'María del Carmen');
    });

    test('bloquea dígitos y signos', () {
      final f = InputRules.name();
      // El dígito y la arroba sencillamente no entran; lo demás sí.
      expect(type(f, 'Juan3', previous: 'Juan'), 'Juan');
      expect(type(f, 'ana@', previous: 'ana'), 'ana');
      expect(type(f, 'Peréz_', previous: 'Peréz'), 'Peréz');
      expect(type(f, 'Ana#2', previous: 'Ana'), 'Ana');
    });

    test('respeta el tope de longitud', () {
      final f = InputRules.name(maxLength: 5);
      expect(type(f, 'abcdefg'), 'abcde');
    });
  });

  group('Correo (formateador)', () {
    test('no deja teclear ni pegar espacios', () {
      final f = InputRules.email();
      expect(type(f, 'ana ruiz', previous: 'ana'), 'ana');
      expect(type(f, ' ana@x.com'), 'ana@x.com');
      expect(type(f, 'ana@ejemplo.com'), 'ana@ejemplo.com');
    });

    test('corta direcciones absurdamente largas', () {
      final f = InputRules.email(maxLength: 10);
      expect(type(f, 'a' * 20), 'a' * 10);
    });
  });

  group('Identificador de acceso', () {
    test('sirve para documento o correo, pero sin espacios', () {
      final f = InputRules.identifier();
      expect(type(f, '12345678Z'), '12345678Z');
      expect(type(f, 'ana@ejemplo.com'), 'ana@ejemplo.com');
      expect(type(f, 'ana ruiz', previous: 'ana'), 'ana');
    });
  });

  group('Texto libre', () {
    test('deja pasar signos que una nota clínica sí usa', () {
      final f = InputRules.freeText();
      expect(type(f, 'TA 120/80, #2 (%)'), 'TA 120/80, #2 (%)');
    });

    test('pero pone un techo de longitud', () {
      final f = InputRules.freeText(maxLength: 4);
      expect(type(f, 'abcdef'), 'abcd');
    });
  });

  group('Fecha de nacimiento', () {
    test('la más antigua admisible es hoy menos 120 años', () {
      final hoy = DateTime(2026, 8, 17);
      final min = InputRules.earliestBirthDate(hoy);
      expect(min, DateTime(1906, 8, 17));
    });

    test('la constante de edad máxima es 120', () {
      expect(InputRules.maxHumanAgeYears, 120);
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
