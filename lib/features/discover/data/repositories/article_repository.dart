import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/article.dart';

class ArticleRepository {
  /// Fetches the articles for a specific language code (e.g. 'es', 'en').
  /// Defaults to 'en' if the file is not found for the requested language.
  Future<List<Article>> fetchArticles(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/articles_$languageCode.json',
      );
      final Iterable jsonList = jsonDecode(jsonString);
      return jsonList.map((model) => Article.fromJson(model)).toList();
    } catch (e) {
      // Fallback to english if not found
      final jsonString = await rootBundle.loadString(
        'assets/data/articles_en.json',
      );
      final Iterable jsonList = jsonDecode(jsonString);
      return jsonList.map((model) => Article.fromJson(model)).toList();
    }
  }
}
