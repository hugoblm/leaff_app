import 'package:hive/hive.dart';

part 'rss_article.g.dart';

@HiveType(typeId: 0)
class RssArticle extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String imageUrl;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String link;

  RssArticle({
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.date,
    required this.description,
    required this.link,
  });
}
