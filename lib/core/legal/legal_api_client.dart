import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart'
    show SyncException;

/// Un documento legal tal y como lo sirve la API.
class LegalDocument {
  /// `privacy` o `terms`.
  final String document;

  /// La versión del texto. Es la que se guarda al aceptar: aceptar sin decir
  /// QUÉ se aceptó no prueba nada dentro de un año, cuando el texto haya
  /// cambiado tres veces.
  final String version;

  /// El idioma **realmente servido**, que puede no ser el que se pidió.
  final String locale;

  /// `false` cuando no había traducción y el servidor cayó al español. La
  /// pantalla lo dice en voz alta: que alguien acepte un contrato creyendo
  /// haberlo leído en su idioma es peor que avisarle de que está en otro.
  final bool translated;

  /// El texto en Markdown, tal cual.
  final String body;

  const LegalDocument({
    required this.document,
    required this.version,
    required this.locale,
    required this.translated,
    required this.body,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
    document: json['document'] as String? ?? '',
    version: json['version'] as String? ?? '',
    locale: json['locale'] as String? ?? '',
    translated: json['translated'] as bool? ?? false,
    body: json['body'] as String? ?? '',
  );
}

/// Los textos legales y la aceptación de los términos.
///
/// **Los textos no viajan dentro de la app a propósito.** Cambiar una política
/// no puede exigir publicar en las tiendas y esperar a que la gente actualice
/// —quien no actualizara seguiría leyendo, y aceptando, un texto retirado—, y
/// la versión exacta que aceptó cada persona tiene que poder consultarse tal y
/// como estaba.
class LegalApiClient {
  static const privacy = 'privacy';
  static const terms = 'terms';

  final http.Client _http;
  final Duration timeout;

  LegalApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  /// Lee un documento. **Sin sesión**: hay que poder leer qué se va a aceptar
  /// antes de tener cuenta, y también después de darse de baja.
  Future<LegalDocument> fetch(String document, {String? locale}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/legal/$document',
    ).replace(queryParameters: locale == null ? null : {'locale': locale});

    final http.Response resp;
    try {
      resp = await _http.get(uri).timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }
    return LegalDocument.fromJson(
      jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Deja escrito que esta persona aceptó [version].
  ///
  /// La fecha la pone el servidor. El servidor rechaza con 409 cualquier
  /// versión que no sea la vigente, así que se manda la que vino con el propio
  /// texto que se acaba de mostrar y no una constante compilada en la app.
  Future<void> acceptTerms(String version) async {
    final http.Response resp;
    try {
      resp = await _http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/me/terms'),
            headers: {
              ...PatientSession.instance.authHeaders,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({'version': version}),
          )
          .timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }
  }

  void close() => _http.close();
}
