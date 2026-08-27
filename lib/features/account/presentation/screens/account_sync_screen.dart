import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/local_data_reset.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/auth/pending_account.dart';
import 'package:myvitals_healthtracker_app/core/widgets/pending_account_banner.dart';
import 'package:myvitals_healthtracker_app/core/constants/countries.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/sync/measurement_read_client.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_service.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/settings_page_header.dart';
import 'package:myvitals_healthtracker_app/core/theme/settings_accent.dart';
import 'package:myvitals_healthtracker_app/core/validation/input_rules.dart';

/// Pantalla de cuenta y sincronización. Reúne los dos flujos:
///  - Paciente de la CLÍNICA: entra con su documento y el código que un agente le dictó
///    por teléfono tras verificar su identidad, y ve la data que se trajo del legacy.
///  - Paciente NUEVO: se registra por la app.
///
/// Con sesión activa, permite sincronizar los registros locales y leer la serie del
/// servidor.
///
/// <b>Pendiente:</b> el alta de paciente nuevo sigue llamando a `/api/v1/auth/register`,
/// que solo existe mientras el servidor corre en modo andamio. El autorregistro con
/// verificación propia está por diseñar; hasta entonces, quien no es paciente todavía
/// tiene que pasar por la clínica.
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

  /// Canjea el código y abre la sesión, con el mismo aislamiento entre pacientes que el
  /// resto de entradas: si el dispositivo traía datos de otro paciente, se borran ANTES de
  /// guardar la sesión.
  Future<void> _redeem(String document, String code) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final profile = context.read<UserProfileProvider>();
    try {
      final session = await _auth.redeemAccessCode(
        documentNumber: document,
        code: code,
      );
      final account = session.account;

      final owner = await currentDataOwner();
      if (owner != null && owner != account.publicId && mounted) {
        await wipeLocalUserData(context);
      }

      await PatientSession.instance.save(
        publicId: account.publicId,
        token: session.token,
        expiresAt: session.expiresAt,
        firstName: account.firstName,
        lastName: account.lastName,
        source: account.source,
      );
      await setDataOwner(account.publicId);

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
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context)!.unexpectedError('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<PatientAccount> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final profile = context.read<UserProfileProvider>();
    try {
      final account = await action();

      // Aislamiento entre pacientes: si el dispositivo tenía datos de OTRO paciente,
      // se borran antes de guardar la sesión (mismo criterio que en el login normal).
      final owner = await currentDataOwner();
      if (owner != null && owner != account.publicId && mounted) {
        await wipeLocalUserData(context);
      }

      await PatientSession.instance.save(
        publicId: account.publicId,
        firstName: account.firstName,
        lastName: account.lastName,
        source: account.source,
      );
      await setDataOwner(account.publicId);
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
    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;
    final session = context.watch<PatientSession>();
    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado común: ícono + título + descripción centrados.
              SettingsPageHeader(
                icon: Icons.sync,
                title: l10n.accountSyncTitle,
                description: l10n.accountSyncDescription,
                accent: SettingsSection.accountSync.tone(Theme.of(context)),
              ),
              const SizedBox(height: 32),
              if (session.isAuthenticated) _loggedIn(session) else _loggedOut(),
            ],
          ),
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
        // El título de la pantalla ya lo pone el encabezado común; aquí sólo
        // queda el texto contextual (según haya o no un alta pendiente).
        Text(
          pending ? l10n.accountPendingBody : l10n.accountLoggedOutBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: surfaces.inkSecondary),
        ),
        if (_error != null) _errorBanner(_error!),
        const SizedBox(height: 20),
        if (pending) ...[
          const PendingAccountBanner(),
          const SizedBox(height: 4),
        ],
        _AccessCodeCard(busy: _busy, onSubmit: _redeem),
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
                  onPressed: PatientSession.instance.clear,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
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

/// Entrada del paciente que ya es de la clínica: documento + el código que le dictaron.
///
/// Pide los dos datos, y no por trámite: el documento acota el intento a una sola cuenta,
/// que es lo que hace que seis dígitos no sean adivinables.
class _AccessCodeCard extends StatefulWidget {
  final bool busy;
  final void Function(String documentNumber, String code) onSubmit;
  const _AccessCodeCard({required this.busy, required this.onSubmit});

  @override
  State<_AccessCodeCard> createState() => _AccessCodeCardState();
}

class _AccessCodeCardState extends State<_AccessCodeCard> {
  final _id = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _ready =>
      _id.text.trim().isNotEmpty && _code.text.trim().length == 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      title: l10n.accountHaveAccount,
      children: [
        Text(
          l10n.accessCodeAccountHint,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).surfaces.inkSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _id,
          // Sin `onChanged` el botón se quedaba deshabilitado para siempre.
          onChanged: (_) => setState(() {}),
          inputFormatters: InputRules.documentId(),
          decoration: InputDecoration(labelText: l10n.identifyFieldLabel),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.accessCodeLabel,
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: widget.busy || !_ready
              ? null
              : () => widget.onSubmit(_id.text.trim(), _code.text.trim()),
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
          // Sin dígitos ni signos: un nombre son letras (con tildes y ñ),
          // espacios y a lo sumo guion o apóstrofo.
          inputFormatters: InputRules.name(),
          decoration: InputDecoration(labelText: l10n.fullName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          // El espacio del autocorrector o de un pegado no entra; la forma la
          // valida InputRules.isEmail (emailMalformed) más abajo.
          inputFormatters: InputRules.email(),
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
