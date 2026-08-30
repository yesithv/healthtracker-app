import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/local_data_reset.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:myvitals_healthtracker_app/core/legal/legal_api_client.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import '../widgets/legal_markdown.dart';

/// Los términos de uso y la política de tratamiento de datos, servidos por la API.
///
/// <h3>Dos modos, una pantalla</h3>
///
/// En **modo lectura** se llega desde Ajustes o desde el alta: se lee y se sale.
/// En **modo aceptación** ([mustAccept]) es la puerta de entrada: no se puede
/// seguir sin aceptar, tampoco con el botón atrás del sistema.
///
/// <h3>Por qué existe el modo aceptación</h3>
///
/// Los pacientes **migrados** entraban sin haber aceptado nada. Habían aceptado
/// los términos de la clínica de nutrición, que es otra empresa; este producto
/// trataba sus datos sin ninguna base propia. Y cuando los términos cambian, lo
/// que firmaron ya no es lo que rige.
class LegalDocumentsScreen extends StatefulWidget {
  /// `true` cuando esta pantalla es la puerta: se sale de ella aceptando o
  /// cerrando sesión, no volviendo atrás.
  final bool mustAccept;

  /// Cuál de los dos se abre primero. Desde la casilla del alta importa: quien
  /// pulsa «política de privacidad» espera ver esa y no la otra.
  final String initialDocument;

  /// A dónde ir tras aceptar.
  final String destination;

  /// El cliente contra el que hablar. Se inyecta en las pruebas; en la app va
  /// el de verdad y esta pantalla lo cierra al salir.
  final LegalApiClient? client;

  const LegalDocumentsScreen({
    super.key,
    this.mustAccept = false,
    this.initialDocument = LegalApiClient.terms,
    this.destination = '/dashboard',
    this.client,
  });

  @override
  State<LegalDocumentsScreen> createState() => _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends State<LegalDocumentsScreen> {
  late final LegalApiClient _client = widget.client ?? LegalApiClient();

  final Map<String, LegalDocument> _loaded = {};

  late String _current = widget.initialDocument;
  bool _loading = true;
  bool _accepting = false;
  String? _error;

  /// La primera lectura no puede ir en `initState`: necesita el idioma, y
  /// `Localizations.localeOf` exige que las dependencias ya estén resueltas.
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(_current);
  }

  @override
  void dispose() {
    // Solo el que creó esta pantalla; el inyectado es de quien lo pasó.
    if (widget.client == null) _client.close();
    super.dispose();
  }

  Future<void> _load(String document) async {
    if (_loaded.containsKey(document)) {
      setState(() {
        _current = document;
        _error = null;
      });
      return;
    }
    setState(() {
      _current = document;
      _loading = true;
      _error = null;
    });

    final locale = Localizations.localeOf(context).languageCode;
    try {
      final doc = await _client.fetch(document, locale: locale);
      if (!mounted) return;
      setState(() {
        _loaded[document] = doc;
        _loading = false;
      });
    } catch (e) {
      debugLogError('Legal.fetch', e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.legalLoadFailed;
      });
    }
  }

  /// Acepta **la versión del texto que se acaba de mostrar**, no una constante
  /// compilada: el servidor rechaza cualquier otra, y con razón —aceptar un
  /// texto que no se ha leído no es aceptar nada—.
  Future<void> _accept() async {
    final terms = _loaded[LegalApiClient.terms];
    if (terms == null) {
      await _load(LegalApiClient.terms);
      return;
    }

    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      await _client.acceptTerms(terms.version);
      if (!mounted) return;
      router.go(widget.destination);
    } catch (e) {
      debugLogError('Legal.accept', e);
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _error = l10n.legalAcceptFailed;
      });
    }
  }

  /// La salida de quien no quiere aceptar. Sin esto la pantalla sería una
  /// trampa: no se puede entrar y tampoco se puede salir.
  Future<void> _declineAndLeave() async {
    final router = GoRouter.of(context);
    await PatientSession.instance.clear();
    if (mounted) await wipeLocalUserData(context);
    router.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final l10n = AppLocalizations.of(context)!;

    // En modo aceptación tampoco hay flecha de volver: enseñar una salida que no
    // lleva a ninguna parte es peor que no enseñarla.
    final PreferredSizeWidget bar = widget.mustAccept
        ? AppBar(
            title: Text(l10n.legalTitle),
            centerTitle: true,
            automaticallyImplyLeading: false,
            backgroundColor: surfaces.brand,
            foregroundColor: surfaces.onBrand,
          )
        : SecondaryAppBar(title: l10n.legalTitle);

    return PopScope(
      // En modo aceptación, el botón atrás del sistema no es una salida: si lo
      // fuera, bastaría pulsarlo para entrar sin aceptar.
      canPop: !widget.mustAccept,
      child: Scaffold(
        backgroundColor: surfaces.canvas,
        appBar: bar,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _tabs(context),
              Expanded(child: _body(context)),
              if (widget.mustAccept) _acceptBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final l10n = AppLocalizations.of(context)!;

    Widget tab(String document, String label) {
      final selected = _current == document;
      return Expanded(
        child: GestureDetector(
          onTap: _accepting ? null : () => _load(document),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? surfaces.brand : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? surfaces.ink : surfaces.inkMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: surfaces.card,
      child: Row(
        children: [
          tab(LegalApiClient.terms, l10n.legalTermsTab),
          tab(LegalApiClient.privacy, l10n.legalPrivacyTab),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final doc = _loaded[_current];
    if (doc == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? l10n.legalLoadFailed, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _load(_current),
                child: Text(l10n.legalRetry),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Cuando no había traducción, decirlo. Que alguien acepte un contrato
        // creyendo haberlo leído en su idioma es peor que avisarle.
        if (!doc.translated) _notice(context, l10n.legalNotTranslated),
        LegalMarkdown(doc.body),
      ],
    );
  }

  Widget _notice(BuildContext context, String text) {
    final clinical = Theme.of(context).clinical;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: clinical.caution.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.translate_rounded,
            size: 18,
            color: clinical.caution.accent,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _acceptBar(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final l10n = AppLocalizations.of(context)!;
    final ready = _loaded.containsKey(LegalApiClient.terms);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: surfaces.card,
        boxShadow: surfaces.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).clinical.alert.accent,
              ),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: _accepting || !ready ? null : _accept,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _accepting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.legalAcceptButton),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _accepting ? null : _declineAndLeave,
            child: Text(
              l10n.legalDecline,
              style: TextStyle(fontSize: 13, color: surfaces.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
