import 'package:flutter/material.dart';
import '../../../../core/widgets/main_app_bar.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/anthropometric_history_card.dart';
import '../widgets/vital_signs_card.dart';
import '../widgets/lipid_profile_card.dart';
import '../widgets/body_composition_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          const MainAppBar(title: 'MY VITALS', subtitle: 'Health Tracker'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              children: const [
                UserProfileCard(),
                SizedBox(height: 24),
                AnthropometricHistoryCard(),
                SizedBox(height: 24),
                VitalSignsCard(),
                SizedBox(height: 24),
                LipidProfileCard(),
                SizedBox(height: 24),
                BodyCompositionCard(),
                SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
