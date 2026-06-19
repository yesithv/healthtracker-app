import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../data/models/article.dart';
import '../../data/repositories/article_repository.dart';
import '../widgets/category_chips.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/article_list_tile.dart';
import '../../../../core/widgets/main_app_bar.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ArticleRepository _repository = ArticleRepository();
  List<Article> _articles = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    final languageCode = AppLocalizations.of(context)!.localeName;
    try {
      final articles = await _repository.fetchArticles(languageCode);
      if (mounted) {
        setState(() {
          _articles = articles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Article> get _filteredArticles {
    if (_selectedCategory == 'all') {
      return _articles.where((a) => a.categoryId != 'daily').toList();
    }
    return _articles.where((a) => a.categoryId == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = context.watch<UserProfileProvider>();

    final Map<String, String> categoryLabels = {
      'all': l10n.discoverCategoryAll,
      'heart': l10n.discoverCategoryHeart,
      'nutrition': l10n.discoverCategoryNutrition,
      'emotional': l10n.discoverCategoryEmotional,
      'sports': l10n.discoverCategorySports,
      'sleep': l10n.discoverCategorySleep,
    };

    final userName = prefs.userName.trim();
    final greetingPrefix = l10n.discoverGreeting(userName);
    final greeting = userName.isEmpty 
        ? greetingPrefix.replaceAll(RegExp(r',\s*$'), '') 
        : greetingPrefix;

    final base64Image = prefs.profileImageBase64;
    
    final dailyArticles = _articles.where((a) => a.categoryId == 'daily').toList();
    final dailyTip = dailyArticles.isNotEmpty 
        ? dailyArticles[DateTime.now().day % dailyArticles.length] 
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          MainAppBar(title: l10n.discover.toUpperCase()),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.discoverSearchHint,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.black45,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: dailyTip != null
                        ? DailyTipCard(article: dailyTip)
                        : const SizedBox.shrink(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: CategoryChips(
                        categories: categoryLabels.values.toList(),
                        selectedCategory:
                            categoryLabels[_selectedCategory] ??
                            l10n.discoverCategoryAll,
                        onSelected: (selectedLabel) {
                          // Find key by label
                          final selectedKey = categoryLabels.entries
                              .firstWhere(
                                (entry) => entry.value == selectedLabel,
                                orElse: () => const MapEntry('all', 'Todos'),
                              )
                              .key;
                          setState(() {
                            _selectedCategory = selectedKey;
                          });
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Text(
                        l10n.discoverRecommended,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final article = _filteredArticles[index];
                        return ArticleListTile(
                          article: article,
                          onTap: () {
                            // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening...')));
                          },
                        );
                      }, childCount: _filteredArticles.length),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100), // Bottom padding
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }
}
