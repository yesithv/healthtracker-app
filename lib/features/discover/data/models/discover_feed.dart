import 'article.dart';
import 'discover_models.dart';

/// The full payload that powers the Discover screen in a single load: daily
/// tips, articles, routines and challenges. This is the exact shape produced by
/// the backoffice "Exportar para la app" action and stored in
/// `assets/data/discover_<lang>.json`.
class DiscoverFeed {
  final List<DailyTip> dailyTips;
  final List<Article> articles;
  final List<Routine> routines;
  final List<Challenge> challenges;

  const DiscoverFeed({
    this.dailyTips = const [],
    this.articles = const [],
    this.routines = const [],
    this.challenges = const [],
  });

  static const empty = DiscoverFeed();

  bool get isEmpty =>
      dailyTips.isEmpty &&
      articles.isEmpty &&
      routines.isEmpty &&
      challenges.isEmpty;

  List<Article> get featuredArticles =>
      articles.where((a) => a.featured).toList();

  /// Articles that are not featured (the regular "Recomendado para ti" list).
  List<Article> get standardArticles =>
      articles.where((a) => !a.featured).toList();

  factory DiscoverFeed.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    }

    return DiscoverFeed(
      dailyTips: parse('dailyTips', DailyTip.fromJson),
      articles: parse('articles', Article.fromJson),
      routines: parse('routines', Routine.fromJson),
      challenges: parse('challenges', Challenge.fromJson),
    );
  }
}
