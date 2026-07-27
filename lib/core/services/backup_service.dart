import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';

class BackupService {
  static const String _version = "1.0";
  static const String _appName = "MyVitals";

  /// Backup format versions this build knows how to import. Reject anything
  /// else so a newer/unknown format isn't restored with wrong assumptions.
  static const List<String> _supportedVersions = ["1.0"];

  /// Generates the backup JSON and shares/downloads it.
  Future<bool> exportBackup(String userName) async {
    try {
      // Fetch all records
      final anthropometric = await AnthropometricRepository.instance.getAll();
      final vitalSigns = await VitalSignsRepository.instance.getAll();
      final lipids = await LipidRepository.instance.getAll();
      final bodyCompositions = await BodyCompositionRepository.instance
          .getAll();

      // Fetch all preferences
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = <String, dynamic>{};

      // Keys matching the preference providers (profile, goals, locale/units)
      final preferenceKeys = [
        'user_language',
        'user_measurement_unit',
        'user_name',
        'user_birth_date',
        'user_email',
        'user_gender',
        'user_activity_level',
        'user_biometric_enabled',
        'medical_goals_enabled',
        'target_weight',
        'target_body_fat',
        'target_muscle_mass',
        'target_visceral_fat',
      ];

      for (var key in preferenceKeys) {
        prefsMap[key] = prefs.get(key);
      }

      // The profile image is no longer kept in prefs on mobile (it lives in a
      // file). Read it from whichever store applies and embed it as base64 so
      // the backup stays portable across devices.
      prefsMap['user_profile_image'] = await _readProfileImageBase64(prefs);

      // Build JSON structure
      final now = DateTime.now();
      final backupData = {
        "version": _version,
        "exported_at": now.toIso8601String(),
        "app": _appName,
        "preferences": prefsMap,
        "records": {
          "anthropometric": anthropometric.map((e) => e.toMap()).toList(),
          "vital_signs": vitalSigns.map((e) => e.toMap()).toList(),
          "lipid": lipids.map((e) => e.toMap()).toList(),
          "body_composition": bodyCompositions.map((e) => e.toMap()).toList(),
        },
      };

      final jsonString = jsonEncode(backupData);

      // Formatting the filename
      final dateStr = DateFormat("ddMMMMyyyy", "en").format(now);
      final timeStr = DateFormat("hh-mm-a").format(now).toUpperCase();
      final sanitizedName = userName.isNotEmpty
          ? userName.replaceAll(RegExp(r'\s+'), '')
          : "User";
      final fileName = "myvitals-$sanitizedName-$dateStr-$timeStr.json";

      if (kIsWeb) {
        // Use XFile.fromData on Web to trigger a download via the share sheet.
        final bytes = utf8.encode(jsonString);
        final xFile = XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType: 'application/json',
        );
        await SharePlus.instance.share(ShareParams(files: [xFile]));
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsString(jsonString);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], subject: 'My Vitals Backup'),
        );
      }

      return true;
    } catch (e) {
      debugPrint("Error exporting backup: $e");
      return false;
    }
  }

  /// Imports a backup from a selected JSON file
  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'myvitals'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = result.files.first;
      String jsonContent;

      if (kIsWeb) {
        if (file.bytes == null) return false;
        jsonContent = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) return false;
        jsonContent = await File(file.path!).readAsString();
      }

      final Map<String, dynamic> backupData = jsonDecode(jsonContent);

      // Validate the file is ours and a format version we support.
      if (backupData['app'] != _appName) return false;
      final version = backupData['version'];
      if (version is! String || !_supportedVersions.contains(version)) {
        return false;
      }

      // Restore preferences
      if (backupData.containsKey('preferences')) {
        final prefsMap = backupData['preferences'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();

        for (var entry in prefsMap.entries) {
          final key = entry.key;
          final value = entry.value;

          // Handled separately below — the image must never go into prefs on
          // mobile, where it is restored as a file instead.
          if (key == 'user_profile_image') continue;

          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          }
        }

        await _writeProfileImageBase64(
          prefs,
          prefsMap['user_profile_image'] as String?,
        );
      }

      // Restore records
      if (backupData.containsKey('records')) {
        final records = backupData['records'] as Map<String, dynamic>;

        if (records.containsKey('anthropometric')) {
          for (var item in records['anthropometric']) {
            await AnthropometricRepository.instance.insert(
              AnthropometricRecord.fromMap(item),
            );
          }
        }

        if (records.containsKey('vital_signs')) {
          for (var item in records['vital_signs']) {
            await VitalSignsRepository.instance.insert(
              VitalSignRecord.fromMap(item),
            );
          }
        }

        if (records.containsKey('lipid')) {
          for (var item in records['lipid']) {
            await LipidRepository.instance.insert(LipidRecord.fromMap(item));
          }
        }

        if (records.containsKey('body_composition')) {
          for (var item in records['body_composition']) {
            await BodyCompositionRepository.instance.insert(
              BodyCompositionRecord.fromMap(item),
            );
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint("Error importing backup: $e");
      return false;
    }
  }

  /// Reads the profile image as base64 from the active store: prefs on web,
  /// the documents-directory file on mobile. Returns null when there is none.
  Future<String?> _readProfileImageBase64(SharedPreferences prefs) async {
    if (kIsWeb) return prefs.getString('user_profile_image');
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_photo.jpg');
      if (await file.exists()) return base64Encode(await file.readAsBytes());
    } catch (_) {}
    return null;
  }

  /// Restores a backup's base64 image into the active store: prefs on web,
  /// the documents-directory file on mobile.
  Future<void> _writeProfileImageBase64(
    SharedPreferences prefs,
    String? base64,
  ) async {
    if (base64 == null || base64.isEmpty) return;
    if (kIsWeb) {
      await prefs.setString('user_profile_image', base64);
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_photo.jpg');
      await file.writeAsBytes(base64Decode(base64), flush: true);
    } catch (_) {}
  }
}
