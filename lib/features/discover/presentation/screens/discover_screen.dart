import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../core/providers/discover_provider.dart';
import '../../../../core/widgets/main_app_bar.dart';
import '../../data/models/article.dart';
import '../../data/models/discover_feed.dart';
import '../../data/models/discover_models.dart';
import '../theme/discover_palette.dart';
import '../widgets/category_chips.dart';
import '../widgets/discover_hero_card.dart';
import '../widgets/discover_section_header.dart';
import '../widgets/discover_skeleton.dart';
import '../widgets/featured_article_card.dart';
import '../widgets/article_card.dart';
import '../widgets/routine_card.dart';
import '../widgets/challenge_card.dart';
import '../widgets/content_detail_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const _categoryKeys = [
    'all',
    'heart',
    'nutrition',
    'emotional',
    'sports',
    'sleep',
  ];

  String _selectedCategory = 'all';
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cheap on every dependency change: no-ops once the feed is cached, so the
    // tab renders instantly instead of showing a spinner.
    final lang = AppLocalizations.of(context)!.localeName;
    context.read<DiscoverProvider>().ensureLoaded(lang);
  }

  String _categoryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'heart':
        return l10n.discoverCategoryHeart;
      case 'nutrition':
        return l10n.discoverCategoryNutrition;
      case 'emotional':
        return l10n.discoverCategoryEmotional;
      case 'sports':
        return l10n.discoverCategorySports;
      case 'sleep':
        return l10n.discoverCategorySleep;
      default:
        return l10n.discoverCategoryAll;
    }
  }

  bool _matchesQuery(String title, String subtitle) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        subtitle.toLowerCase().contains(q);
  }

  bool _inCategory(String category) =>
      _selectedCategory == 'all' || category == _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<DiscoverProvider>();
    final feed = provider.feed;
    final prefs = context.watch<UserProfileProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          MainAppBar(title: l10n.discover.toUpperCase()),
          Expanded(
            child: provider.isColdStart
                ? const DiscoverSkeleton()
                : RefreshIndicator(
                    color: DiscoverPalette.brand,
                    onRefresh: () => provider.refresh(l10n.localeName),
                    child: _buildFeed(context, l10n, feed, prefs),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(
    BuildContext context,
    AppLocalizations l10n,
    DiscoverFeed feed,
    UserProfileProvider prefs,
  ) {
    // Filtered collections.
    final featured = _selectedCategory == 'all' && _query.isEmpty
        ? feed.featuredArticles
        : const <Article>[];
    final articles = feed.standardArticles
        .where((a) => _inCategory(a.category) && _matchesQuery(a.title, a.subtitle))
        .toList();
    final routines = feed.routines
        .where((r) => _inCategory(r.category) && _matchesQuery(r.title, r.subtitle))
        .toList();
    // Challenges are general (no category); show them on "all" or when searching.
    final challenges = feed.challenges
        .where((c) =>
            (_selectedCategory == 'all') && _matchesQuery(c.title, c.goal))
        .toList();

    final tip = _dailyTip(feed);
    final userName = prefs.userName.trim();
    final greeting = userName.isEmpty
        ? l10n.discoverGreeting(userName).replaceAll(RegExp(r',\s*$'), '')
        : l10n.discoverGreeting(userName);
    final base64Image = prefs.profileImageBase64;

    final nothingToShow = featured.isEmpty &&
        articles.isEmpty &&
        routines.isEmpty &&
        challenges.isEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Greeting + avatar.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: const Color(0xFFE6A88B),
                  radius: 20,
                  backgroundImage: base64Image != null
                      ? MemoryImage(base64Decode(base64Image))
                      : null,
                  child: base64Image == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
        // Search.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: l10n.discoverSearchHint,
                prefixIcon: const Icon(Icons.search, color: Colors.black45),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
        // Daily tip hero.
        if (tip != null && _query.isEmpty)
          SliverToBoxAdapter(child: DiscoverHeroCard(tip: tip.text)),
        // Category chips.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: CategoryChips(
              categoryKeys: _categoryKeys,
              selectedKey: _selectedCategory,
              labelFor: (k) => _categoryLabel(l10n, k),
              onSelected: (k) => setState(() => _selectedCategory = k),
            ),
          ),
        ),

        // Featured rail.
        if (featured.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DiscoverSectionHeader(
              title: l10n.discoverFeatured,
              accent: DiscoverPalette.brand,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: featured.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => FeaturedArticleCard(
                  article: featured[i],
                  onTap: () => _openArticle(context, l10n, featured[i]),
                ),
              ),
            ),
          ),
        ],

        // Routines rail.
        if (routines.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DiscoverSectionHeader(
              title: l10n.discoverRoutines,
              accent: DiscoverPalette.of('sports').accent,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 208,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: routines.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) => RoutineCard(
                  routine: routines[i],
                  onTap: () => _openRoutine(context, l10n, routines[i]),
                ),
              ),
            ),
          ),
        ],

        // Articles list.
        if (articles.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DiscoverSectionHeader(
              title: _query.isEmpty && _selectedCategory == 'all'
                  ? l10n.discoverRecommended
                  : l10n.discoverArticles,
              accent: DiscoverPalette.of('heart').accent,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => ArticleCard(
                  article: articles[i],
                  onTap: () => _openArticle(context, l10n, articles[i]),
                ),
                childCount: articles.length,
              ),
            ),
          ),
        ],

        // Challenges list.
        if (challenges.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: DiscoverSectionHeader(
              title: l10n.discoverChallenges,
              accent: DiscoverPalette.of('nutrition').accent,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => ChallengeCard(
                  challenge: challenges[i],
                  onTap: () => _openChallenge(context, l10n, challenges[i]),
                ),
                childCount: challenges.length,
              ),
            ),
          ),
        ],

        if (nothingToShow)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 56, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.discoverEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  DailyTip? _dailyTip(DiscoverFeed feed) {
    if (feed.dailyTips.isEmpty) return null;
    return feed.dailyTips[DateTime.now().day % feed.dailyTips.length];
  }

  // --- detail openers --------------------------------------------------------

  void _openArticle(BuildContext context, AppLocalizations l10n, Article a) {
    final style = DiscoverPalette.of(a.category);
    showDiscoverDetailSheet(
      context,
      accent: style.accent,
      icon: style.icon,
      kicker: _categoryLabel(l10n, a.category),
      title: a.title,
      body: a.body.isNotEmpty ? a.body : a.subtitle,
      chips: [
        DetailChip(
          icon: Icons.schedule_rounded,
          label: '${a.readTime} ${l10n.discoverMinRead}',
        ),
        if (a.author.isNotEmpty)
          DetailChip(icon: Icons.person_rounded, label: a.author),
      ],
    );
  }

  void _openRoutine(BuildContext context, AppLocalizations l10n, Routine r) {
    final style = DiscoverPalette.of(r.category);
    final level = switch (r.level) {
      ContentLevel.principiante => l10n.discoverLevelBeginner,
      ContentLevel.intermedio => l10n.discoverLevelIntermediate,
      ContentLevel.avanzado => l10n.discoverLevelAdvanced,
    };
    showDiscoverDetailSheet(
      context,
      accent: style.accent,
      icon: style.icon,
      kicker: l10n.discoverRoutines,
      title: r.title,
      body: r.subtitle,
      chips: [
        DetailChip(icon: Icons.signal_cellular_alt_rounded, label: level),
        DetailChip(
          icon: Icons.timer_outlined,
          label: '${r.durationMin} ${l10n.discoverMinShort}',
        ),
        if (r.exercises > 0)
          DetailChip(
            icon: Icons.fitness_center_rounded,
            label: l10n.discoverExercises('${r.exercises}'),
          ),
      ],
      ctaLabel: l10n.discoverStart,
    );
  }

  void _openChallenge(BuildContext context, AppLocalizations l10n, Challenge c) {
    final color = DiscoverPalette.statusColor(c.status);
    final status = switch (c.status) {
      ChallengeStatus.activo => l10n.discoverStatusActive,
      ChallengeStatus.programado => l10n.discoverStatusScheduled,
      ChallengeStatus.finalizado => l10n.discoverStatusFinished,
    };
    showDiscoverDetailSheet(
      context,
      accent: color,
      icon: Icons.emoji_events_rounded,
      kicker: l10n.discoverChallenges,
      title: c.title,
      body: c.goal,
      chips: [
        DetailChip(icon: Icons.flag_rounded, label: status),
        if (c.durationDays > 0)
          DetailChip(
            icon: Icons.event_rounded,
            label: l10n.discoverDaysShort('${c.durationDays}'),
          ),
      ],
      ctaLabel:
          c.status == ChallengeStatus.finalizado ? null : l10n.discoverJoin,
    );
  }
}
