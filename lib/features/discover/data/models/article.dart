/// A Discover article. Enriched to mirror the backoffice "Artículos" content
/// type (title, author, category, published) plus the app-facing presentation
/// fields the mobile Discover feed renders (subtitle, readTime, featured).
///
/// [fromJson] stays tolerant of the legacy `articles_*.json` shape (`categoryId`,
/// `imageAssetName`) so nothing breaks while content migrates to `discover_*.json`.
class Article {
  final String id;

  /// Taxonomy key shared with the app category chips and the backoffice
  /// (`heart`, `nutrition`, `emotional`, `sports`, `sleep`, ...).
  final String category;
  final String title;
  final String subtitle;

  /// Optional long-form body shown in the reader sheet. When empty the sheet
  /// falls back to the subtitle.
  final String body;
  final String author;

  /// Estimated read time in minutes, kept as a string to match content authoring.
  final String readTime;

  /// Featured articles are surfaced in the hero carousel at the top of Discover.
  final bool featured;

  const Article({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    this.body = '',
    this.author = '',
    this.readTime = '3',
    this.featured = false,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      // Prefer the new `category` key, fall back to legacy `categoryId`.
      category: (json['category'] ?? json['categoryId'] ?? 'general') as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      body: json['body'] as String? ?? '',
      author: json['author'] as String? ?? '',
      readTime: (json['readTime'] ?? '3').toString(),
      featured: json['featured'] as bool? ?? false,
    );
  }
}
