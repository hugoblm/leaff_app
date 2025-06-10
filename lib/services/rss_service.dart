import 'dart:convert';
import 'dart:math' show min; // Ajout de l'import pour la fonction min
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Pour ChangeNotifier
import 'package:flutter/material.dart'; // Pour ChangeNotifier et Notifier

class RSSArticle {
  final String title;
  final String description;
  final String link;
  final String? imageUrl;
  final DateTime? pubDate;
  final String category;
  final String? content;  // Contenu complet de l'article

  RSSArticle({
    required this.title,
    required this.description,
    required this.link,
    this.imageUrl,
    this.pubDate,
    required this.category,
    this.content,
  });

  factory RSSArticle.fromJson(Map<String, dynamic> json, String source) {
    // Try to get date from pubDate or dc:date
    final date = json['pubDate'] ?? json['dc:date'];
    
    // Essayer de récupérer le contenu complet depuis différents champs possibles
    final content = json['content:encoded'] ?? 
                   json['content'] ?? 
                   json['description'];
    
    return RSSArticle(
      title: _cleanText(json['title'] ?? ''),
      description: _cleanText(json['description'] ?? ''),
      link: json['link'] ?? '',
      imageUrl: _extractImageUrl(json),
      pubDate: _parseDate(date),
      category: _getCategoryFromSource(source),
      content: content != null ? _cleanText(content) : null,
    );
  }

  // Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'imageUrl': imageUrl,
      'pubDate': pubDate?.toIso8601String(),
      'category': category,
      'content': content,
    };
  }

  // Create from cached JSON
  factory RSSArticle.fromCachedJson(Map<String, dynamic> json) {
    return RSSArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['imageUrl'],
      pubDate: json['pubDate'] != null ? DateTime.parse(json['pubDate']) : null,
      category: json['category'] ?? 'Écologie',
      content: json['content'],
    );
  }

  static String _cleanText(String text) {
    // Remove HTML tags and decode HTML entities
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    // Try to extract image from different possible fields
    if (json['enclosure'] != null && json['enclosure']['url'] != null) {
      return json['enclosure']['url'];
    }
    if (json['media:thumbnail'] != null && json['media:thumbnail']['url'] != null) {
      return json['media:thumbnail']['url'];
    }
    return null;
  }

  static DateTime? _parseDate(dynamic dateString) {
    if (dateString == null) return null;
    
    final str = dateString.toString().trim();
    print('Attempting to parse date: $str');
    
    // Try standard ISO format
    try {
      return DateTime.parse(str);
    } catch (_) {
      // Try RSS date format (RFC 822)
      try {
        return DateTime.parse(str.replaceAll(' +0000', 'Z'));
      } catch (_) {
        // Try another common RSS format with GMT
        try {
          return DateTime.parse(str.replaceAll(' GMT', '+0000'));
        } catch (_) {
          // Try parsing with just date
          try {
            return DateTime.parse(str.split(',')[1].trim());
          } catch (_) {
            // Try more formats using intl
            try {
              // Try RSS date format with intl
              final formats = [
                'EEE, dd MMM yyyy HH:mm:ss Z', // RFC 822
                'yyyy-MM-dd HH:mm:ss',
                'yyyy-MM-dd',
                'dd MMM yyyy',
                'dd/MM/yyyy',
                'MM/dd/yyyy',
              ];
              
              for (var format in formats) {
                try {
                  return DateFormat(format).parse(str);
                } catch (_) {}
              }
            } catch (_) {}
            
            // If all fails, return null
            print('Could not parse date: $str');
            return null;
          }
        }
      }
    }
  }

  static String _getCategoryFromSource(String source) {
    switch (source) {
      case 'reporterre':
        return 'Environnement';
      case 'lowtechmagazine':
        return 'Low-tech';
      case 'actu-environnement':
        return 'Actualités';
      case 'actualites-news-environnement':
        return 'News Écolo';
      default:
        return 'Écologie';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case 'Environnement':
        return '🌱';
      case 'Low-tech':
        return '⚙️';
      case 'Actualités':
        return '📰';
      case 'News Écolo':
        return '🌍';
      default:
        return '♻️';
    }
  }
}

class RSSService with ChangeNotifier {
  static const List<Map<String, String>> _rssFeeds = [
    {
      'url': 'https://reporterre.net/spip.php?page=backend-simple',
      'source': 'reporterre',
    },
    {
      'url': 'https://solar.lowtechmagazine.com/fr/posts/index.xml',
      'source': 'lowtechmagazine',
    },
    {
      'url': 'https://www.actu-environnement.com/flux/rss/environnement/',
      'source': 'actu-environnement',
    },
    {
      'url': 'https://www.actualites-news-environnement.com/rss.php',
      'source': 'actualites-news-environnement',
    },
  ];

  static const String _cacheKey = 'cached_articles';
  static const String _lastFetchKey = 'rss_last_fetch';
  static const String _lastCleanupKey = 'rss_last_cleanup';

  List<RSSArticle> _cachedArticles = [];
  bool _isLoading = false;
  String? _error;

  List<RSSArticle> get cachedArticles => List.unmodifiable(_cachedArticles);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<RSSArticle>> fetchAllArticles({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Vérifier si nous devons effectuer le nettoyage mensuel
      await _performMonthlyCleanup();

      // Vérifier si nous avons des données en cache et si elles sont récentes
      if (!forceRefresh) {
        final lastFetchTime = await _getLastFetchTime();
        final now = DateTime.now();
        final difference = now.difference(lastFetchTime);

        // Si les données ont moins de 30 minutes, on utilise le cache
        if (difference.inMinutes < 30) {
          final cachedArticles = await _loadFromCache();
          if (cachedArticles.isNotEmpty) {
            _cachedArticles = cachedArticles;
            _isLoading = false;
            notifyListeners();
            return _cachedArticles;
          }
        }
      }

      // Si on arrive ici, il faut rafraîchir les données
      List<RSSArticle> allArticles = [];
      int successCount = 0;

      // Parcourir tous les flux RSS
      for (var feed in _rssFeeds) {
        try {
          final articles = await _fetchFeedArticles(feed['url']!, feed['source']!);
          allArticles.addAll(articles);
          successCount++;
        } catch (e) {
          // Si une erreur se produit avec un flux, on continue avec les autres
          print('Erreur lors de la récupération du flux ${feed['url']}: $e');
        }
      }

      // Si aucun flux n'a pu être chargé, on lance une exception
      if (successCount == 0 && allArticles.isEmpty) {
        throw Exception('Impossible de charger les articles depuis les flux RSS');
      }

      // Trier les articles par date (du plus récent au plus ancien)
      allArticles.sort((a, b) => (b.pubDate ?? DateTime(1970)).compareTo(a.pubDate ?? DateTime(1970)));

      // Limiter le nombre d'articles pour économiser de l'espace de stockage
      final limitedArticles = allArticles.take(50).toList();

      // Mettre à jour le cache et l'état
      _cachedArticles = limitedArticles;
      await _saveToCache(limitedArticles);
      await _updateLastFetchTime();
      
      _isLoading = false;
      notifyListeners();
      
      return _cachedArticles;
    } catch (e) {
      // En cas d'erreur, essayer de retourner le cache s'il existe
      try {
        final cachedArticles = await _loadFromCache();
        if (cachedArticles.isNotEmpty) {
          _cachedArticles = cachedArticles;
          _isLoading = false;
          notifyListeners();
          return _cachedArticles;
        }
      } catch (cacheError) {
        print('Erreur lors du chargement du cache: $cacheError');
      }
      
      _error = 'Impossible de charger les articles: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<List<RSSArticle>> _fetchFeedArticles(String url, String source) async {
    try {
      print('Fetching RSS feed from $url');
      
      // Vérifier l'URL
      if (url.isEmpty) {
        throw Exception('L\'URL du flux RSS est vide');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Leaff App RSS Reader',
          'Accept': 'application/rss+xml, application/xml, text/xml',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('La réponse du serveur est vide');
        }
        
        print('Successfully fetched RSS feed (status: ${response.statusCode})');
        print('Response length: ${response.body.length} bytes');
        
        try {
          // Parsing du flux RSS avec xml2json
          final xmlParser = Xml2Json();
          xmlParser.parse(response.body);
          print('XML parsed successfully');
          
          final jsonString = xmlParser.toParker();
          print('JSON conversion successful');
          
          final jsonData = json.decode(jsonString);
          print('JSON parsed successfully');

          final articles = _parseArticles(jsonData, source);
          
          if (articles.isEmpty) {
            print('Aucun article trouvé dans le flux RSS');
          } else {
            print('${articles.length} articles trouvés dans le flux RSS');
          }
          
          return articles;
        } catch (parseError) {
          print('Erreur lors du parsing du flux RSS: $parseError');
          print('Début du contenu XML: ${response.body.substring(0, min(200, response.body.length))}...');
          throw Exception('Format du flux RSS invalide: $parseError');
        }
      } else {
        throw Exception('Échec du chargement du flux RSS (${response.statusCode})');
      }
    } on http.ClientException catch (e) {
      print('Erreur de connexion lors de la récupération du flux RSS: $e');
      throw Exception('Impossible de se connecter au serveur: ${e.message}');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        print('Délai d\'attente dépassé lors de la récupération du flux RSS');
        throw Exception('Délai d\'attente dépassé lors de la connexion au serveur');
      }
      rethrow;
    } catch (e, stackTrace) {
      print('Erreur inattendue lors de la récupération du flux RSS: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Erreur lors de la récupération du flux RSS: $e');
    }
  }

  List<RSSArticle> _parseArticles(Map<String, dynamic> jsonData, String source) {
    final List<RSSArticle> articles = [];
    
    try {
      print('Parsing feed from $source');
      print('JSON data structure: ${jsonData.keys.join(', ')}');
      
      // Normaliser la structure des données pour gérer différents formats de flux
      dynamic items;
      
      // Format RSS standard
      if (jsonData['rss'] != null) {
        jsonData = jsonData['rss'];
      }
      
      // Format RSS avec channel
      if (jsonData['channel'] != null) {
        jsonData = jsonData['channel'];
      }
      
      // Trouver les articles dans différentes structures possibles
      if (jsonData['item'] != null) {
        items = jsonData['item'];
        print('Found items at channel level');
      } else if (jsonData['items'] != null) {
        items = jsonData['items'];
        print('Found items in items array');
      } else if (jsonData['entry'] != null) {
        // Format Atom
        items = jsonData['entry'];
        print('Found entries in Atom format');
      } else if (jsonData['rss'] != null && jsonData['rss']['channel'] != null) {
        // Autre variante de structure RSS
        final channel = jsonData['rss']['channel'];
        items = channel['item'] ?? channel['items'] ?? channel['entry'];
        print('Found items in nested RSS structure');
      } else if (jsonData['content'] != null && jsonData['content']['item'] != null) {
        items = jsonData['content']['item'];
        print('Found items in content section');
      } else {
        print('No items found in RSS/Atom format');
        print('Raw JSON data: $jsonData');
        return [];
      }
      
      // Si aucun article n'a été trouvé, retourner une liste vide
      if (items == null) {
        print('Aucun article trouvé dans le flux RSS');
        return [];
      }
      
      // Gérer le cas où il n'y a qu'un seul article (certains flux retournent un objet au lieu d'une liste)
      if (items is Map<String, dynamic>) {
        try {
          final article = RSSArticle.fromJson(items, source);
          articles.add(article);
          print('Article unique trouvé: ${article.title}');
        } catch (e, stackTrace) {
          print('Erreur lors du parsing d\'un article unique: $e');
          print('Stack trace: $stackTrace');
          print('Données de l\'article: $items');
        }
      } 
      // Gérer le cas où il y a plusieurs articles (liste)
      else if (items is List) {
        print('${items.length} articles trouvés dans le flux');
        int parsedCount = 0;
        
        for (var item in items) {
          try {
            if (item is Map<String, dynamic>) {
              final article = RSSArticle.fromJson(item, source);
              articles.add(article);
              parsedCount++;
            } else {
              print('Article ignoré - format invalide: $item');
            }
          } catch (e, stackTrace) {
            print('Erreur lors du parsing d\'un article: $e');
            print('Stack trace: $stackTrace');
            print('Données de l\'article en erreur: $item');
          }
        }
        
        print('$parsedCount articles parsés avec succès sur ${items.length}');
      } else {
        print('Format d\'article non reconnu: ${items.runtimeType}');
      }
      
      return articles;
    } catch (e, stackTrace) {
      print('Erreur lors du parsing des articles: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> _saveToCache(List<RSSArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir les articles en JSON et ajouter la source
      final articlesJson = articles.map((article) {
        final json = article.toJson();
        // Ajouter la source si elle n'est pas déjà présente
        if (!json.containsKey('source')) {
          json['source'] = article.category;
        }
        return json;
      }).toList();
      
      await prefs.setString(_cacheKey, jsonEncode(articlesJson));
      _cachedArticles = List.from(articles); // Mettre à jour le cache en mémoire
    } catch (e) {
      print('Erreur lors de la sauvegarde en cache: $e');
      rethrow;
    }
  }

  Future<List<RSSArticle>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(cachedData);
      _cachedArticles = jsonList.map((json) {
        // Utiliser une source par défaut pour les articles en cache
        final source = json['source'] ?? 'cache';
        return RSSArticle.fromJson(json, source);
      }).toList();
      return _cachedArticles;
    } catch (e) {
      print('Error loading from cache: $e');
      _cachedArticles = [];
      return [];
    }
  }

  Future<void> _updateLastFetchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error updating last fetch time: $e');
    }
  }

  Future<DateTime> _getLastFetchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getString(_lastFetchKey);
      return lastFetch != null ? DateTime.parse(lastFetch) : DateTime(1970);
    } catch (e) {
      return DateTime(1970);
    }
  }

  Future<void> _performMonthlyCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getString(_lastCleanupKey);
      
      if (lastCleanup == null) {
        await prefs.setString(_lastCleanupKey, DateTime.now().toIso8601String());
        return;
      }
      
      final lastCleanupDate = DateTime.parse(lastCleanup);
      if (DateTime.now().difference(lastCleanupDate).inDays >= 30) {
        await clearCache();
        await prefs.setString(_lastCleanupKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error during monthly cleanup: $e');
    }
  }

  /// Rafraîchit manuellement les articles en forçant un rechargement
  Future<void> refreshArticles() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Forcer le rechargement des articles
      await fetchAllArticles(forceRefresh: true);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Impossible de rafraîchir les articles: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// Vide le cache des articles
  Future<void> clearCache() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_lastFetchKey);
      _cachedArticles = [];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Échec de la suppression du cache: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Récupère le contenu complet d'un article à partir de son URL
  Future<String> fetchFullArticleContent(String articleUrl) async {
    try {
      print('Fetching full article content from: $articleUrl');
      
      final response = await http.get(
        Uri.parse(articleUrl),
        headers: {
          'User-Agent': 'Leaff App RSS Reader',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Ici, vous pourriez utiliser un package comme 'flutter_widget_from_html' ou 'html'
        // pour parser le HTML et extraire le contenu principal de l'article.
        // Pour l'instant, nous retournons simplement le HTML brut.
        return response.body;
      } else {
        throw Exception('Failed to load article content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching full article content: $e');
      throw Exception('Failed to load article content: $e');
    }
  }
}
