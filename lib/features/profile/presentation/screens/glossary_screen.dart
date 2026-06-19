import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../data/glossary_data.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groups = GlossaryData.getGroups(l10n);

    // Filter: for each group, keep only terms matching query
    final filteredGroups = _query.isEmpty
        ? groups
        : groups
            .map((g) => GlossaryGroup(
                  titleKey: g.titleKey,
                  icon: g.icon,
                  color: g.color,
                  terms: g.terms
                      .where((t) =>
                          t.name.toLowerCase().contains(_query) ||
                          t.definition.toLowerCase().contains(_query))
                      .toList(),
                ))
            .where((g) => g.terms.isNotEmpty)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const SecondaryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: l10n.helpGlossarySearchHint,
                      hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (filteredGroups.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            l10n.helpNoResults,
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredGroups.map((g) => _buildGroup(context, g, l10n)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, GlossaryGroup group, AppLocalizations l10n) {
    final title = _resolveGroupTitle(group.titleKey, l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: group.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(group.icon, color: group.color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: group.color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Terms
        ...group.terms.map((term) => _buildTermCard(term, group.color, l10n)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTermCard(GlossaryTerm term, Color color, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            term.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          iconColor: color,
          collapsedIconColor: const Color(0xFFCBD5E1),
          children: [
            Text(
              term.definition,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.6,
              ),
            ),
            if (term.normalRange != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${l10n.helpGlossaryNormalRange}: ${term.normalRange}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resolveGroupTitle(String key, AppLocalizations l10n) {
    switch (key) {
      case 'helpGlossaryGroupAnthropo':
        return l10n.helpGlossaryGroupAnthropo;
      case 'helpGlossaryGroupVitals':
        return l10n.helpGlossaryGroupVitals;
      case 'helpGlossaryGroupLipid':
        return l10n.helpGlossaryGroupLipid;
      case 'helpGlossaryGroupBody':
        return l10n.helpGlossaryGroupBody;
      default:
        return key;
    }
  }
}
