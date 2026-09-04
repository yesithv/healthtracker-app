import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_api_client.dart'
    show SyncException;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Descarga **todo lo que el servidor guarda** sobre el paciente (`GET /me/export`).
///
/// <h3>Por qué existe habiendo ya dos exportaciones</h3>
///
/// No se solapan, y por eso no se retira ninguna:
///
///  - el **PDF de historia clínica** es la versión presentable, para enseñar en consulta;
///  - la **copia de seguridad** es local y se puede volver a importar en la app;
///  - **esto** es el volcado crudo de la base, que es lo que pide el derecho de acceso y
///    portabilidad (habeas data). Es además lo único de los tres que incluye lo que el
///    paciente nunca tecleó aquí —su historia migrada del legacy— tal y como está
///    almacenada.
///
/// El endpoint existía desde hace tiempo y **no lo llamaba nadie**: el derecho estaba
/// implementado en el servidor y no había forma de ejercerlo desde la app.
class DataExportService {
  final http.Client _http;
  final Duration timeout;

  DataExportService({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _http = httpClient ?? http.Client();

  /// Trae el volcado tal cual lo devuelve el servidor, sin interpretarlo.
  ///
  /// Se devuelve el texto y no un modelo a propósito: una exportación tiene que poder
  /// contrastarse con lo que hay en la base, y parsearla para volver a serializarla solo
  /// añadiría un sitio donde perder un campo.
  Future<String> fetchMine() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/me/export');
    final http.Response resp;
    try {
      resp = await _http
          .get(uri, headers: PatientSession.instance.authHeaders)
          .timeout(timeout);
    } catch (e) {
      throw SyncException('No se pudo conectar con la API: $e');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw SyncException('La API respondió ${resp.statusCode}: ${resp.body}');
    }
    return utf8.decode(resp.bodyBytes);
  }

  /// Descarga el volcado y lo entrega al sistema para guardarlo o compartirlo.
  ///
  /// Devuelve un [ShareOutcome] para que la pantalla distinga compartir de cancelar:
  /// cancelar el diálogo no puede leerse como «tus datos se descargaron».
  Future<ShareOutcome> downloadAndShare(String userName) async {
    final String dump;
    try {
      dump = await fetchMine();
    } catch (e) {
      debugLogError('DataExport.fetch', e);
      return ShareOutcome.error;
    }

    try {
      final fileName = _fileNameFor(userName);
      final ShareResult result;
      if (kIsWeb) {
        // En web el «compartir» de un archivo es la descarga del navegador.
        result = await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                Uint8List.fromList(utf8.encode(dump)),
                name: fileName,
                mimeType: 'application/json',
              ),
            ],
          ),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        await File(path).writeAsString(dump);
        result = await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], subject: 'My Vitals'),
        );
      }
      return shareOutcomeOf(result);
    } catch (e) {
      debugLogError('DataExport.share', e);
      return ShareOutcome.error;
    }
  }

  void close() => _http.close();

  /// Mismo criterio de nombre que la copia de seguridad, para que los dos archivos se
  /// reconozcan juntos en la carpeta de descargas.
  static String _fileNameFor(String userName) {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final time = DateFormat('hh-mm-a').format(now).toUpperCase();
    final name = userName.trim().isEmpty
        ? 'User'
        : userName.replaceAll(RegExp(r'\s+'), '');
    return 'myvitals-datos-$name-$date-$time.json';
  }
}
