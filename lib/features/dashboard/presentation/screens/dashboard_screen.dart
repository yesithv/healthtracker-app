import 'package:flutter/material.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/main_app_bar.dart';
import '../../../../core/widgets/pending_account_banner.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/anthropometric_history_card.dart';
import '../widgets/vital_signs_card.dart';
import '../widgets/lipid_profile_card.dart';
import '../widgets/body_composition_card.dart';
import '../widgets/dashboard_summary_row.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).surfaces.canvas,
      body: Column(
        children: [
          const MainAppBar(title: 'MY VITALS', subtitle: 'Health Tracker'),
          Expanded(
            child: ListView(
              // Tope firme al final: sin rebote ni overscroll, el scroll se
              // siente cerrado justo en las minicards (no «infinito»).
              physics: const ClampingScrollPhysics(),
              // Menos margen lateral: las tarjetas ganan ancho y su contenido
              // llega un poco más cerca del borde de cada una.
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              children: const [
                // Solo se pinta si el alta quedó pendiente; en cuanto la cuenta
                // se crea, desaparece por sí mismo.
                PendingAccountBanner(),
                UserProfileCard(),
                SizedBox(height: 24),
                AnthropometricHistoryCard(),
                SizedBox(height: 24),
                VitalSignsCard(),
                SizedBox(height: 24),
                LipidProfileCard(),
                SizedBox(height: 24),
                BodyCompositionCard(),
                SizedBox(height: 24),
                DashboardSummaryRow(),
                // Colchón mínimo para que el botón flotante no tape el borde
                // inferior; el scroll termina en las minicards, sin cola en
                // blanco (antes 80 dejaba un tramo scrolleable vacío).
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
