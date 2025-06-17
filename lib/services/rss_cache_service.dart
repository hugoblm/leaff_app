import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/rss_article.dart';

class RssCacheService {
  static const String _boxName = 'rss_articles_box';
  static const String _lastFetchKey = 'last_fetch';

  /// Vide complètement le cache RSS (articles + métadonnées)
  static Future<void> clearCache() async {
    await Hive.box<RssArticle>(_boxName).clear();
    await Hive.box(_boxName + '_meta').clear();
  }

  /// Initialise Hive et enregistre l'adapter pour les articles RSS
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RssArticleAdapter());
    }
    await Hive.openBox<RssArticle>(_boxName);
    await Hive.openBox(_boxName + '_meta');
  }

  /// Sauvegarde la liste d'articles et la date de fetch
  static Future<void> saveArticles(List<RssArticle> articles) async {
    final box = Hive.box<RssArticle>(_boxName);
    await box.clear();
    await box.addAll(articles);
    final metaBox = Hive.box(_boxName + '_meta');
    metaBox.put(_lastFetchKey, DateTime.now().toIso8601String());
  }

  /// Récupère la liste d'articles en cache
  static List<RssArticle> getCachedArticles() {
    final box = Hive.box<RssArticle>(_boxName);
    return box.values.toList();
  }

  /// Date du dernier fetch (null si jamais fetché)
  static DateTime? getLastFetchDate() {
    final metaBox = Hive.box(_boxName + '_meta');
    final iso = metaBox.get(_lastFetchKey);
    if (iso is String) {
      return DateTime.tryParse(iso);
    }
    return null;
  }

  /// Supprime le cache si plus vieux que [maxAgeDays]
  static Future<void> purgeOldCache({int maxAgeDays = 7}) async {
    final lastFetch = getLastFetchDate();
    if (lastFetch != null && DateTime.now().difference(lastFetch).inDays > maxAgeDays) {
      await Hive.box<RssArticle>(_boxName).clear();
      await Hive.box(_boxName + '_meta').clear();
    }
  }
}
