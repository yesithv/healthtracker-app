import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Impide que la app vuelva a afirmar cosas que dejaron de ser ciertas.
///
/// **Por qué existe.** Durante meses, Ajustes → Legal decía: «Todos los datos se
/// almacenan localmente en el dispositivo. My Vitals no recopila, transmite ni
/// comparte información personal con terceros. No existen cuentas de usuario ni
/// servidores de datos.» Era verdad cuando la app era local. Después llegaron la
/// cuenta, la sesión, el servidor, la subida de todas las mediciones y el panel
/// desde el que el staff de la clínica ve la historia clínica. Cada fase lo fue
/// haciendo menos cierto **y nadie tocó el texto**: no había nada que fallara.
///
/// Eso es exactamente lo que una prueba puede sujetar y una revisión humana no:
/// nadie relee los cinco catálogos de traducción al añadir un endpoint. Aquí se
/// lee el texto que la app enseña y se rechaza cualquier afirmación de que los
/// datos no salen del teléfono o de que no hay cuentas ni servidores.
///
/// **Si esta prueba falla**, la respuesta correcta casi nunca es aflojar el
/// patrón: es que el texto volvió a mentir, o que la app dejó de sincronizar y
/// entonces hay que borrar la regla junto con la sincronización.
void main() {
  /// Cada patrón va con el idioma en el que se escribió la frase original.
  /// Están sueltos a propósito —«no sale de tu teléfono», «no salen del
  /// dispositivo»—: lo que se persigue es la afirmación, no una redacción.
  const forbidden = <String, List<String>>{
    'es': [
      r'no (?:se )?(?:sale|salen|abandonan?)[^.]{0,40}(?:dispositivo|teléfono|móvil)',
      r'(?:solo|únicamente|exclusivamente)[^.]{0,30}(?:en (?:el|tu) )?(?:dispositivo|teléfono|móvil)',
      r'no (?:existen|hay)[^.]{0,30}(?:cuentas|servidores)',
      r'no (?:recopila|recopilamos|transmite|transmitimos|comparte|compartimos)[^.]{0,60}(?:terceros|información personal)',
      r'almacenan[^.]{0,20}localmente en el dispositivo',
    ],
    'en': [
      r'(?:never|does not|do not|doesn.t|don.t)[^.]{0,30}leaves?[^.]{0,30}(?:device|phone)',
      r'(?:only|solely)[^.]{0,25}on (?:your|the) (?:device|phone)',
      r'there are no[^.]{0,30}(?:accounts|servers)',
      r'(?:does not|do not|doesn.t|don.t)[^.]{0,20}(?:collect|transmit|share)[^.]{0,60}(?:third part|personal information)',
      r'stored locally on the[^.]{0,20}device',
    ],
    'pt': [
      r'(?:não|nao)[^.]{0,30}(?:sai|saem|abandonam)[^.]{0,30}(?:dispositivo|telem[oó]vel|telefone)',
      r'(?:não|nao) (?:existem|há|ha)[^.]{0,30}(?:contas|servidores)',
      r'(?:não|nao) (?:recolhe|recolhemos|coleta|coletamos|transmite|partilha|compartilha)[^.]{0,60}(?:terceiros|informa)',
      r'armazenados? localmente no dispositivo',
    ],
    'it': [
      r'non[^.]{0,30}(?:esce|escono|lascia|lasciano)[^.]{0,30}(?:dispositivo|telefono)',
      r'non (?:esistono|ci sono)[^.]{0,30}(?:account|server)',
      r'non (?:raccoglie|raccogliamo|trasmette|condivide|condividiamo)[^.]{0,60}(?:terze parti|informazioni personali)',
      r'archiviati localmente sul dispositivo',
    ],
    'de': [
      r'(?:verl[aä]sst|verlassen)[^.]{0,30}(?:nie|niemals|nicht)[^.]{0,30}(?:Ger[aä]t|Telefon)',
      r'es gibt keine[^.]{0,30}(?:Konten|Server)',
      r'(?:erfasst|übermittelt|uebermittelt|teilt)[^.]{0,60}keine[^.]{0,40}(?:Dritten|Informationen)',
      r'keine[^.]{0,20}(?:Benutzerkonten|Datenserver)',
      r'ausschließlich[^.]{0,25}auf (?:dem|deinem) Ger[aä]t',
    ],
  };

  group('lo que la app dice sobre los datos ·', () {
    for (final entry in forbidden.entries) {
      final language = entry.key;
      final patterns = entry.value
          .map((p) => RegExp(p, caseSensitive: false))
          .toList();

      test('app_$language.arb no afirma que los datos no salen del teléfono', () {
        final file = File('lib/l10n/app_$language.arb');
        expect(file.existsSync(), isTrue, reason: 'falta ${file.path}');

        final catalogue =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final offenders = <String>[];

        catalogue.forEach((key, value) {
          // Las entradas '@clave' son metadatos, no texto que nadie lea.
          if (key.startsWith('@') || value is! String) return;
          for (final pattern in patterns) {
            if (pattern.hasMatch(value)) {
              offenders.add('$key → «$value»  (choca con ${pattern.pattern})');
            }
          }
        });

        expect(
          offenders,
          isEmpty,
          reason:
              'Estos textos afirman algo que el sistema no cumple: las mediciones '
              'se suben al servidor, hay cuenta de usuario y el staff de la clínica '
              've la historia clínica desde el panel.\n${offenders.join('\n')}',
        );
      });
    }

    test('el catálogo dice quién puede ver la historia clínica', () {
      // La otra mitad de lo mismo: no basta con quitar la mentira, hay que
      // decir lo que pasa. Si alguien borra este apartado, esta prueba lo dice.
      final catalogue =
          jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
              as Map<String, dynamic>;

      expect(catalogue['helpLegalWhoSeesBody'], isA<String>());
      expect(
        (catalogue['helpLegalWhoSeesBody'] as String).toLowerCase(),
        contains('clínica'),
      );
      expect(
        (catalogue['helpLegalPrivacyBody'] as String).toLowerCase(),
        contains('servidor'),
      );
    });
  });
}
