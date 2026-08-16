import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/providers/measuring_device_provider.dart';
import 'package:myvitals_healthtracker_app/core/sync/device_api_client.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/settings_page_layout.dart';

/// Selector "¿qué báscula de bioimpedancia usas?". Fuente de verdad editable siempre; la
/// elección se guarda local y se sincroniza a la API, que la usa para interpretar (el semáforo
/// bajo/normal/alto). Si el usuario no usa ninguna, solo verá indicadores manuales.
class MeasuringDeviceScreen extends StatefulWidget {
  const MeasuringDeviceScreen({super.key});

  @override
  State<MeasuringDeviceScreen> createState() => _MeasuringDeviceScreenState();
}

class _MeasuringDeviceScreenState extends State<MeasuringDeviceScreen> {
  /// La marca del tema activo. Era una constante de clase con el azul de
  /// «Pulso Clínico» escrito a mano.
  Color get _primary => Theme.of(context).surfaces.brand;

  @override
  void initState() {
    super.initState();
    // Lee la elección local y refresca catálogo/selección desde la API (best-effort).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeasuringDeviceProvider>().load();
    });
  }

  Future<void> _select(MeasuringDevice device) async {
    final provider = context.read<MeasuringDeviceProvider>();
    // El texto se resuelve ANTES del await: después, usar el context para
    // leerlo sería usarlo cruzando un hueco asíncrono.
    final message = AppLocalizations.of(
      context,
    )!.deviceSelectedSaved(device.name);
    await provider.select(device);
    _confirm(message, provider.pendingSync);
  }

  Future<void> _selectNone() async {
    final provider = context.read<MeasuringDeviceProvider>();
    final message = AppLocalizations.of(context)!.deviceNoneSaved;
    await provider.selectNone();
    _confirm(message, provider.pendingSync);
  }

  void _confirm(String message, bool pending) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final text = pending ? l10n.deviceWillSyncLater(message) : message;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;
    final provider = context.watch<MeasuringDeviceProvider>();

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      // Mismo esqueleto que Información personal, Idioma y Unidades: el widget
      // común aporta el encabezado (ícono centrado + título + descripción) y el
      // botón «Guardar preferencias», para que el botón sea idéntico en color,
      // dimensiones y borde en todas las pantallas de la cuenta.
      body: SingleChildScrollView(
        child: SettingsPageLayout(
          icon: Icons.monitor_heart_outlined,
          title: l10n.deviceScreenTitle,
          description: l10n.deviceScreenDescription,
          // La elección ya se guarda y sincroniza al tocar cada opción (igual
          // que en Idioma y Unidades); el botón sólo confirma y regresa.
          onConfirm: () => Navigator.pop(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerCard(),
              const SizedBox(height: 20),
              if (provider.loadingCatalog)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (provider.catalogError != null)
                _noticeBanner(l10n.deviceCatalogError),

              // Opción "ninguna".
              _deviceTile(
                title: l10n.deviceNoneTitle,
                subtitle: l10n.deviceNoneSubtitle,
                icon: Icons.block,
                selected: provider.usesNoDevice,
                onTap: _selectNone,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                child: Text(
                  l10n.deviceAvailableScales,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: surfaces.inkMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Catálogo.
              ...provider.catalog.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _deviceTile(
                    title: d.name,
                    subtitle: '${d.brand} · ${d.model}',
                    icon: Icons.monitor_heart_outlined,
                    selected: provider.selectedCode == d.code,
                    onTap: () => _select(d),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.deviceWhyItMatters,
              style: TextStyle(fontSize: 13, height: 1.5, color: surfaces.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBanner(String text) {
    final clinical = Theme.of(context).clinical;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: clinical.caution.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: clinical.caution.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: clinical.caution.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final surfaces = Theme.of(context).surfaces;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _primary.withValues(alpha: 0.1)
              : Theme.of(context).surfaces.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _primary : surfaces.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (selected ? _primary : surfaces.inkMuted).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? _primary : surfaces.inkSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected ? _primary : surfaces.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: surfaces.inkMuted),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? _primary : surfaces.inkMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
