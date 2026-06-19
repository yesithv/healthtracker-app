import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/secondary_app_bar.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final categories = [
      _FaqCategory(id: 'all', label: l10n.discoverCategoryAll, icon: Icons.apps_rounded),
      _FaqCategory(id: 'general', label: l10n.helpFaqCatGeneral, icon: Icons.info_outline),
      _FaqCategory(id: 'data', label: l10n.helpFaqCatData, icon: Icons.storage_outlined),
      _FaqCategory(id: 'biometrics', label: l10n.helpFaqCatBiometrics, icon: Icons.fingerprint),
      _FaqCategory(id: 'export', label: l10n.helpFaqCatExport, icon: Icons.file_download_outlined),
    ];

    final faqs = _getFaqs(l10n);
    final filtered = _selectedCategory == 'all'
        ? faqs
        : faqs.where((f) => f.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const SecondaryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // Category chips
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final selected = _selectedCategory == cat.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF0D48A0)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // FAQ items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: filtered
                        .map((faq) => _buildFaqTile(faq))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(_FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: faq.color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(faq.icon, color: faq.color, size: 18),
          ),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          iconColor: const Color(0xFF0D48A0),
          collapsedIconColor: const Color(0xFF94A3B8),
          children: [
            Text(
              faq.answer,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FaqItem> _getFaqs(AppLocalizations l10n) {
    return [
      _FaqItem(
        category: 'general',
        question: l10n.helpFaqQ1,
        answer: l10n.helpFaqA1,
        icon: Icons.info_outline,
        color: const Color(0xFF0D48A0),
      ),
      _FaqItem(
        category: 'data',
        question: l10n.helpFaqQ2,
        answer: l10n.helpFaqA2,
        icon: Icons.cloud_off_outlined,
        color: const Color(0xFF10B981),
      ),
      _FaqItem(
        category: 'data',
        question: l10n.helpFaqQ3,
        answer: l10n.helpFaqA3,
        icon: Icons.wifi_off_outlined,
        color: const Color(0xFF10B981),
      ),
      _FaqItem(
        category: 'biometrics',
        question: l10n.helpFaqQ4,
        answer: l10n.helpFaqA4,
        icon: Icons.fingerprint,
        color: const Color(0xFF8B5CF6),
      ),
      _FaqItem(
        category: 'export',
        question: l10n.helpFaqQ5,
        answer: l10n.helpFaqA5,
        icon: Icons.file_download_outlined,
        color: const Color(0xFFF59E0B),
      ),
      _FaqItem(
        category: 'general',
        question: l10n.helpFaqQ6,
        answer: l10n.helpFaqA6,
        icon: Icons.straighten,
        color: const Color(0xFF0D48A0),
      ),
      _FaqItem(
        category: 'data',
        question: l10n.helpFaqQ7,
        answer: l10n.helpFaqA7,
        icon: Icons.delete_outline,
        color: const Color(0xFFEF4444),
      ),
      _FaqItem(
        category: 'general',
        question: l10n.helpFaqQ8,
        answer: l10n.helpFaqA8,
        icon: Icons.local_hospital_outlined,
        color: const Color(0xFFEF4444),
      ),
    ];
  }
}

class _FaqCategory {
  final String id;
  final String label;
  final IconData icon;
  const _FaqCategory({required this.id, required this.label, required this.icon});
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;
  final IconData icon;
  final Color color;
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
    required this.icon,
    required this.color,
  });
}
