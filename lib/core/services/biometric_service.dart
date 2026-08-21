import 'package:local_auth/local_auth.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if the device has biometric hardware and is currently enrolled to use it.
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on LocalAuthException catch (e) {
      debugLogError('Biometric.isAvailable', e);
      return false;
    }
  }

  /// Attempts to authenticate the user using biometrics.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } on LocalAuthException catch (e) {
      debugLogError('Biometric.authenticate', e);
      return false;
    }
  }
}
