class Article {
  final String id;
  final String categoryId;
  final String title;
  final String subtitle;
  final String readTime;
  final String imageAssetName;

  Article({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.readTime,
    required this.imageAssetName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      readTime: json['readTime'] as String,
      imageAssetName: json['imageAssetName'] as String,
    );
  }
}
