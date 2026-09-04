import 'package:flutter/material.dart';

import 'package:myvitals_healthtracker_app/core/config/api_config.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_api_client.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Por qué canales acepta el paciente que se le contacte.
///
/// <h3>Qué había antes</h3>
///
/// `app.patient_consent` admite `source = 'APP'` desde la V14 y **no lo escribía
/// nadie**: los tres canales los decidía el staff desde el panel, y la persona a
/// la que se llama no tenía dónde decir que no. Aquí es donde lo dice.
///
/// <h3>Tres estados, no dos</h3>
///
/// Un canal que la persona nunca ha respondido **no es un «no»**. Se pinta
/// aparte —el interruptor arranca apagado pero la tarjeta dice que no consta— y
/// solo viaja lo que ella toca: mandar los tres cada vez convertiría abrir esta
/// pantalla en una respuesta que nadie dio.
///
/// Se guarda al momento y no por el sincronizador del perfil: una revocación es
/// una decisión, no una preferencia de pantalla, y tiene que confirmarse o
/// fallar a la vista.
class ContactConsentsCard extends StatefulWidget {
  /// Se inyecta en las pruebas.
  final ProfileApiClient? client;

  const ContactConsentsCard({super.key, this.client});

  @override
  State<ContactConsentsCard> createState() => _ContactConsentsCardState();
}

class _ContactConsentsCardState extends State<ContactConsentsCard> {
  late final ProfileApiClient _client = widget.client ?? ProfileApiClient();

  ServerConsents _consents = const ServerConsents();
  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  bool get _hasServer =>
      ApiConfig.isConfigured &&
      PatientSession.instance.isAuthenticated &&
      !DemoSession.instance.isActive;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_hasServer) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await _client.fetchMine();
      if (!mounted) return;
      setState(() {
        _consents = profile.consents;
        _loading = false;
      });
    } catch (e) {
      debugLogError('Consents.load', e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// Manda **solo el canal tocado**. Los otros dos no se mencionan, así que se
  /// quedan como estaban.
  Future<void> _toggle(String channel, bool granted) async {
    final previous = _consents;
    final updated = ServerConsents(
      phone: channel == 'phone' ? granted : previous.phone,
      messages: channel == 'messages' ? granted : previous.messages,
      email: channel == 'email' ? granted : previous.email,
    );
    setState(() {
      _consents = updated;
      _saving = true;
      _failed = false;
    });

    try {
      await _client.save(
        consents: ServerConsents(
          phone: channel == 'phone' ? granted : null,
          messages: channel == 'messages' ? granted : null,
          email: channel == 'email' ? granted : null,
        ),
      );
      if (mounted) setState(() => _saving = false);
    } catch (e) {
      debugLogError('Consents.save', e);
      if (!mounted) return;
      // Se deshace: dejar el interruptor donde lo puso la persona diría que su
      // revocación quedó guardada cuando no lo está.
      setState(() {
        _consents = previous;
        _saving = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    final l10n = AppLocalizations.of(context)!;

    if (!_hasServer || _loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: surfaces.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.consentsTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: surfaces.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.consentsDescription,
            style: TextStyle(fontSize: 12, color: surfaces.inkMuted),
          ),
          const SizedBox(height: 8),
          _channel('phone', l10n.consentsPhone, _consents.phone),
          _channel('messages', l10n.consentsMessages, _consents.messages),
          _channel('email', l10n.consentsEmail, _consents.email),
          if (_failed) ...[
            const SizedBox(height: 8),
            Text(
              l10n.consentsSaveFailed,
              style: TextStyle(fontSize: 12, color: clinical.alert.accent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _channel(String key, String label, bool? granted) {
    final surfaces = Theme.of(context).surfaces;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: surfaces.ink)),
              // «No consta» no es «no». Decirlo evita que la persona crea que ya
              // respondió que sí a algo que nunca le preguntaron.
              if (granted == null)
                Text(
                  l10n.consentsUnset,
                  style: TextStyle(fontSize: 11, color: surfaces.inkMuted),
                ),
            ],
          ),
        ),
        Switch(
          value: granted ?? false,
          onChanged: _saving ? null : (value) => _toggle(key, value),
        ),
      ],
    );
  }
}
