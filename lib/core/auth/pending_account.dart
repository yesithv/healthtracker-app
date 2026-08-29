import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/countries.dart';
import '../providers/user_profile_provider.dart';

/// Los datos que hacen falta para crear la cuenta, ya resueltos.
///
/// El alta diferida recibe ESTO y no el [UserProfileProvider] a propósito: el
/// provider carga la foto de perfil por canales de plataforma, así que dependerlo
/// haría que esta lógica no se pudiera probar sin arrancar media app. Aquí queda
/// aritmética pura más una llamada de red.
@immutable
class AccountDraft {
  const AccountDraft({
    required this.firstName,
    required this.email,
    this.birthDate,
    this.sex,
    this.phone,
    this.countryIso,
  });

  final String firstName;
  final String email;
  final DateTime? birthDate;
  final String? sex;

  /// Teléfono en formato internacional, ya con prefijo.
  final String? phone;

  final String? countryIso;

  /// Construye el borrador desde el perfil local, que es la fuente de verdad.
  factory AccountDraft.fromProfile(UserProfileProvider profile) {
    // País: el elegido en el picker de prefijo o, si nunca lo tocó, el del
    // locale del dispositivo (el backend valida el código y descarta lo que no
    // reconozca, así que nunca hace fallar el alta).
    final country =
        Countries.byIso(profile.userCountryCode) ?? Countries.deviceDefault();
    final localPhone = profile.userPhone.replaceAll(RegExp(r'[^0-9]'), '');

    return AccountDraft(
      firstName: profile.userName.trim().isEmpty
          ? 'Paciente'
          : profile.userName.trim(),
      email: profile.userEmail.trim(),
      birthDate: profile.birthDate,
      sex: profile.userGender.isEmpty ? null : profile.userGender,
      phone: localPhone.isEmpty ? null : '${country.dialCode}$localPhone',
      countryIso: country.iso,
    );
  }
}

/// ALTA DIFERIDA — la cuenta que quedó pendiente de crear por falta de red.
///
/// La cuenta es obligatoria para usar la app, pero exigir que el servidor esté
/// disponible EN ESE INSTANTE convertiría un corte de red en un muro: el usuario
/// rellena sus datos, se queda fuera y los pierde. Así que cuando el alta falla
/// por transporte —sin conexión, timeout, servidor caído— se marca como
/// pendiente, el usuario entra y sigue registrando indicadores en el dispositivo;
/// la cuenta se crea en el primer intento que salga bien.
///
/// NO se guarda una copia del perfil aquí. Los datos ya viven en
/// [UserProfileProvider] (persistido en `SharedPreferences`), que es la única
/// fuente de verdad: así, si el usuario corrige un correo mal escrito antes de
/// reintentar, el reintento usa el corregido y no una foto vieja.
///
/// Singleton, como [PatientSession], para que la puerta de arranque pueda
/// consultarlo sin depender del árbol de widgets.
class PendingAccountStore extends ChangeNotifier {
  PendingAccountStore._();
  static final PendingAccountStore instance = PendingAccountStore._();

  static const _kPending = 'pending_account_registration';
  static const _kLastError = 'pending_account_last_error';

  bool _isPending = false;
  String? _lastError;

  /// Hay un alta esperando a poder salir al servidor.
  bool get isPending => _isPending;

  /// Motivo del último intento fallido, para poder mostrárselo al usuario.
  String? get lastError => _lastError;

  /// Carga el estado persistido (llamar al arrancar la app, junto a la sesión).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPending = prefs.getBool(_kPending) ?? false;
      _lastError = prefs.getString(_kLastError);
    } catch (e) {
      debugPrint('No se pudo leer el alta pendiente: $e');
    }
    notifyListeners();
  }

  Future<void> markPending({String? reason}) async {
    _isPending = true;
    _lastError = reason;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPending, true);
      if (reason == null) {
        await prefs.remove(_kLastError);
      } else {
        await prefs.setString(_kLastError, reason);
      }
    } catch (e) {
      debugPrint('No se pudo guardar el alta pendiente: $e');
    }
  }

  /// Actualiza solo el motivo del último fallo, sin tocar el estado pendiente.
  Future<void> noteFailure(String reason) => markPending(reason: reason);

  Future<void> clear() async {
    _isPending = false;
    _lastError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPending);
      await prefs.remove(_kLastError);
    } catch (e) {
      debugPrint('No se pudo limpiar el alta pendiente: $e');
    }
  }
}

/// Cómo terminó un intento de crear la cuenta diferida.

/// Lleva a la persona a la puerta con su correo ya escrito.
///
/// Antes aquí había un alta diferida: si al terminar el onboarding no había red, la cuenta se
/// creaba sola en cuanto la hubiera. Con la puerta por correo eso ya no es posible ni deseable
/// —una cuenta nace cuando alguien demuestra que ese buzón es suyo—, así que lo que queda es
/// llevarle a terminar el paso que falta.
void goToAccessDoor(BuildContext context, {String? email}) {
  GoRouter.of(context).go('/login', extra: email);
}
