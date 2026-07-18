import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/providers/measuring_device_provider.dart';
import 'package:myvitals_healthtracker_app/core/sync/device_api_client.dart';

/// Selector "¿qué báscula de bioimpedancia usas?". Fuente de verdad editable siempre; la
/// elección se guarda local y se sincroniza a la API, que la usa para interpretar (el semáforo
/// bajo/normal/alto). Si el usuario no usa ninguna, solo verá indicadores manuales.
class MeasuringDeviceScreen extends StatefulWidget {
  const MeasuringDeviceScreen({super.key});

  @override
  State<MeasuringDeviceScreen> createState() => _MeasuringDeviceScreenState();
}

class _MeasuringDeviceScreenState extends State<MeasuringDeviceScreen> {
  static const _primary = Color(0xFF0D48A0);

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
    await provider.select(device);
    _confirm('${device.name} seleccionada.', provider.pendingSync);
  }

  Future<void> _selectNone() async {
    final provider = context.read<MeasuringDeviceProvider>();
    await provider.selectNone();
    _confirm('Guardado: no usas bioimpedancia.', provider.pendingSync);
  }

  void _confirm(String message, bool pending) {
    if (!mounted) return;
    final text = pending ? '$message Se sincronizará cuando haya conexión.' : message;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeasuringDeviceProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Mi dispositivo de medición'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          _headerCard(),
          const SizedBox(height: 20),
          if (provider.loadingCatalog)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (provider.catalogError != null)
            _noticeBanner('No se pudo actualizar el catálogo. Mostrando las opciones guardadas.'),

          // Opción "ninguna".
          _deviceTile(
            title: 'No uso ninguna',
            subtitle: 'Solo registraré medidas manuales (peso, cintura, talla).',
            icon: Icons.block,
            selected: provider.usesNoDevice,
            onTap: _selectNone,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8, top: 8),
            child: Text(
              'BÁSCULAS DISPONIBLES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Catálogo.
          ...provider.catalog.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _deviceTile(
                  title: d.name,
                  subtitle: '${d.brand} · ${d.model}',
                  icon: Icons.monitor_heart_outlined,
                  selected: provider.selectedCode == d.code,
                  onTap: () => _select(d),
                ),
              )),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _primary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cada báscula de bioimpedancia interpreta la grasa, el músculo y la grasa visceral '
              'con rangos propios. Dinos cuál usas para mostrarte si tus valores están bajos, '
              'normales o altos. Puedes cambiarlo cuando quieras.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBanner(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFF92400E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E))),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _primary : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (selected ? _primary : const Color(0xFF94A3B8)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? _primary : const Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: selected ? _primary : const Color(0xFF1E293B),
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? _primary : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
