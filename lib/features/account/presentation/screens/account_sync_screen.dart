import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/auth/pending_account.dart';
import 'package:myvitals_healthtracker_app/core/widgets/pending_account_banner.dart';
import 'package:myvitals_healthtracker_app/core/constants/countries.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_service.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/validation/input_rules.dart';

/// Pantalla de cuenta y sincronización (andamio de Fase 0). Reúne los dos flujos:
///  - Paciente MIGRADO: inicia sesión con su documento + clave (1234) y ve la data
///    que se trajo del legacy.
///  - Paciente NUEVO: se registra por la app (queda en la BD y el backoffice lo ve).
/// Con sesión activa, permite sincronizar los registros locales y leer la serie del
/// servidor.
class AccountSyncScreen extends StatefulWidget {
  const AccountSyncScreen({super.key});

  @override
  State<AccountSyncScreen> createState() => _AccountSyncScreenState();
}

class _AccountSyncScreenState extends State<AccountSyncScreen> {
  /// La marca del tema activo. Era una constante de clase con el azul de
  /// «Pulso Clínico» escrito a mano.
  Color get _blue => Theme.of(context).surfaces.brand;

  final _auth = AuthApiClient();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _auth.close();
    super.dispose();
  }

  Future<void> _run(Future<PatientAccount> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final profile = context.read<UserProfileProvider>();
    try {
      final account = await action();
      await PatientSession.instance.save(
        publicId: account.publicId,
        firstName: account.firstName,
        lastName: account.lastName,
        source: account.source,
      );
      // Igual que en /verify: el perfil local se llena con lo que el servidor sabe.
      final fullName = [
        account.firstName,
        account.lastName,
      ].where((s) => s != null && s.trim().isNotEmpty).join(' ');
      await profile.hydrateIdentity(
        name: fullName,
        email: account.email,
        birthDate: account.birthDate,
        gender: account.genderForApp,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(
        () => _error = AppLocalizations.of(context)!.unexpectedError('$e'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Sincroniza. Si el alta seguía pendiente, primero crea la cuenta: sin
  /// identidad de paciente el servidor no acepta registros, así que sincronizar
  /// sin ese paso no haría nada. Al crearse la sesión, SyncService se dispara
  /// solo, pero se llama igual para que el usuario vea respuesta inmediata.
  Future<void> _syncNow() async {
    final profile = context.read<UserProfileProvider>();
    final sync = context.read<SyncService>();

    if (PendingAccountStore.instance.isPending) {
      final result = await flushPendingAccount(
        AccountDraft.fromProfile(profile),
      );
      if (!mounted) return;
      if (!result.created) {
        setState(() => _error = result.message);
        return;
      }
      setState(() => _error = null);
    }
    await sync.syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final session = context.watch<PatientSession>();
    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: session.isAuthenticated ? _loggedIn(session) : _loggedOut(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- logged out

  Widget _loggedOut() {
    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;
    // Con un alta pendiente, el usuario ya rellenó sus datos: lo que necesita es
    // que salgan al servidor, no volver a registrarse desde cero. El aviso va
    // primero y trae su propio botón para intentarlo.
    final pending = context.watch<PendingAccountStore>().isPending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accountYourAccount,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pending ? l10n.accountPendingBody : l10n.accountLoggedOutBody,
          style: TextStyle(color: surfaces.inkSecondary),
        ),
        if (_error != null) _errorBanner(_error!),
        const SizedBox(height: 20),
        if (pending) ...[
          const PendingAccountBanner(),
          const SizedBox(height: 4),
        ],
        _LoginCard(
          busy: _busy,
          onSubmit: (id, pass) =>
              _run(() => _auth.login(identifier: id, password: pass)),
        ),
        const SizedBox(height: 16),
        _RegisterCard(
          busy: _busy,
          onSubmit: (first, email, doc) => _run(
            () => _auth.register(
              firstName: first,
              email: email,
              documentNumber: doc,
              // País del perfil (picker de prefijo) o del locale: captura
              // silenciosa; el backend descarta códigos fuera de catálogo.
              country:
                  (Countries.byIso(
                            context.read<UserProfileProvider>().userCountryCode,
                          ) ??
                          Countries.deviceDefault())
                      .iso,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- logged in

  Widget _loggedIn(PatientSession session) {
    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;
    final sync = context.watch<SyncService>();
    final name = [
      session.firstName,
      session.lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _blue,
                  child: Icon(Icons.person, color: surfaces.onBrand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? l10n.accountFallbackName : name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        session.isMigrated
                            ? l10n.accountFromLegacy
                            : l10n.accountCreatedInApp,
                        style: TextStyle(
                          color: surfaces.inkSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => PatientSession.instance.clear(),
                  child: Text(l10n.accountSignOut),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _card(
          children: [
            Text(
              l10n.accountSyncSection,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              sync.message ?? l10n.accountSyncBody,
              style: TextStyle(color: surfaces.inkSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _blue),
              onPressed: sync.isSyncing ? null : _syncNow,
              icon: sync.isSyncing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: surfaces.onBrand,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                sync.isSyncing ? l10n.accountSyncing : l10n.accountSyncNow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ServerDataCard(),
      ],
    );
  }

  // --------------------------------------------------------------------- utils

  Widget _errorBanner(String msg) {
    final theme = Theme.of(context);
    final clinical = theme.clinical;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: clinical.alert.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: clinical.alert.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: theme.type.body.copyWith(color: clinical.alert.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final surfaces = Theme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  final bool busy;
  final void Function(String identifier, String password) onSubmit;
  const _LoginCard({required this.busy, required this.onSubmit});

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _id = TextEditingController();
  final _pass = TextEditingController(text: '1234');

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      title: l10n.accountHaveAccount,
      children: [
        TextField(
          controller: _id,
          // Mismo caso que en el alta: sin `onChanged` el botón se quedaba
          // deshabilitado para siempre.
          onChanged: (_) => setState(() {}),
          inputFormatters: InputRules.documentId(),
          decoration: InputDecoration(labelText: l10n.identifyFieldLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pass,
          obscureText: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.verifyPasswordLabel),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: widget.busy || _id.text.trim().isEmpty
              ? null
              : () => widget.onSubmit(_id.text.trim(), _pass.text),
          child: Text(AppLocalizations.of(context)!.introSignIn),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatefulWidget {
  final bool busy;
  final void Function(String firstName, String email, String? documentNumber)
  onSubmit;
  const _RegisterCard({required this.busy, required this.onSubmit});

  @override
  State<_RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<_RegisterCard> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _doc = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _doc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    // El correo mal escrito se avisa mientras se escribe, pero sólo cuando ya
    // hay algo: nadie quiere que le griten por un campo que aún no ha tocado.
    final emailMalformed = email.isNotEmpty && !InputRules.isEmail(email);
    final canSubmit =
        !widget.busy &&
        _name.text.trim().isNotEmpty &&
        InputRules.isEmail(email);

    return _Section(
      title: l10n.accountNewHere,
      children: [
        TextField(
          controller: _name,
          // Sin esto el botón nunca se habilitaba: su estado se calcula al
          // construir, y escribir en un `TextEditingController` no reconstruye
          // nada por sí solo. El formulario estaba muerto.
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.fullName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            labelText: l10n.emailLabel,
            errorText: emailMalformed ? l10n.validationEmailFormat : null,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _doc,
          onChanged: (_) => setState(() {}),
          inputFormatters: InputRules.documentId(),
          decoration: InputDecoration(labelText: l10n.accountDocumentOptional),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: canSubmit
              ? () => widget.onSubmit(
                  _name.text.trim(),
                  email,
                  _doc.text.trim().isEmpty ? null : _doc.text.trim(),
                )
              : null,
          child: Text(l10n.accountCreateAccount),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: surfaces.brand,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Trae y muestra la serie del paciente desde el servidor (data del legacy + app).
class _ServerDataCard extends StatefulWidget {
  @override
  State<_ServerDataCard> createState() => _ServerDataCardState();
}

class _ServerDataCardState extends State<_ServerDataCard> {
  final _client = MeasurementReadClient();
  bool _loading = false;
  String? _error;
  List<ServerMeasurement>? _data;

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _client.fetchMine();
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mi data en el servidor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: _loading ? null : _load,
                child: const Text('Cargar'),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: clinical.alert.accent)),
          if (_data != null && _data!.isEmpty)
            Text(
              'Sin datos en el servidor todavía.',
              style: TextStyle(color: surfaces.inkSecondary),
            ),
          if (_data != null && _data!.isNotEmpty)
            ..._data!
                .take(50)
                .map(
                  (m) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${m.indicatorName}: ${m.value ?? '—'} ${m.unit ?? ''}'
                          .trim(),
                    ),
                    subtitle: Text(
                      '${m.measuredAt.toLocal()}'.split('.').first,
                    ),
                    trailing: Chip(
                      label: Text(
                        m.isFromLegacy ? 'legacy' : m.source.toLowerCase(),
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: m.isFromLegacy
                          ? clinical.info.surface
                          : clinical.optimal.surface,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
