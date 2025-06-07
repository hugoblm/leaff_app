import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

class RSSService {
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

  static const String _cacheKey = 'rss_articles_cache';
  static const String _lastFetchKey = 'rss_last_fetch';
  static const String _lastCleanupKey = 'rss_last_cleanup';

  Future<List<RSSArticle>> fetchAllArticles({bool forceRefresh = false}) async {
    try {
      // Check if we need to clean up old cache
      await _performMonthlyCleanup();

      // Try to load from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedArticles = await _loadFromCache();
        if (cachedArticles.isNotEmpty) {
          final lastFetch = await _getLastFetchTime();
          // Use cache if last fetch was less than 1 hour ago
          if (lastFetch != null && DateTime.now().difference(lastFetch).inHours < 1) {
            print('Using cached articles (${cachedArticles.length} articles)');
            return cachedArticles;
          }
        }
      }

      print('Fetching fresh articles from RSS feeds...');
      List<RSSArticle> allArticles = [];

      for (var feed in _rssFeeds) {
        try {
          final articles = await _fetchFeedArticles(feed['url']!, feed['source']!);
          allArticles.addAll(articles);
        } catch (e) {
          print('Error fetching ${feed['source']}: $e');
          // Continue with other feeds even if one fails
        }
      }

      // Filter articles to only include those from the last week
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      print('Filtering articles from last week...');
      print('Total articles before filtering: ${allArticles.length}');
      
      // First, separate articles with and without pubDate
      final articlesWithDate = allArticles.where((article) {
        return article.pubDate != null && article.pubDate!.isAfter(oneWeekAgo);
      }).toList();
      
      final articlesWithoutDate = allArticles.where((article) {
        return article.pubDate == null;
      }).toList();
      
      print('Articles with date in last week: ${articlesWithDate.length}');
      print('Articles without date: ${articlesWithoutDate.length}');
      
      // Combine articles with date and without date (keeping the most recent)
      allArticles = [...articlesWithDate, ...articlesWithoutDate];
      
      // Sort by publication date (newest first), null dates last
      allArticles.sort((a, b) {
        if (a.pubDate == null && b.pubDate == null) return 0;
        if (a.pubDate == null) return 1;
        if (b.pubDate == null) return -1;
        return b.pubDate!.compareTo(a.pubDate!);
      });

      // Take the most recent 20 articles
      final limitedArticles = allArticles.take(20).toList();
      print('Total articles after filtering and sorting: ${limitedArticles.length}');
      print('First article date: ${limitedArticles.first.pubDate}');
      print('Last article date: ${limitedArticles.last.pubDate}');

      // Save to cache
      await _saveToCache(limitedArticles);
      await _updateLastFetchTime();

      print('Fetched and cached ${limitedArticles.length} articles');
      return limitedArticles;
    } catch (e) {
      print('Error in fetchAllArticles: $e');
      // Try to return cached articles as fallback
      final cachedArticles = await _loadFromCache();
      if (cachedArticles.isNotEmpty) {
        print('Returning cached articles as fallback');
        return cachedArticles;
      }
      throw Exception('Failed to fetch articles and no cache available: $e');
    }
  }

  Future<List<RSSArticle>> _fetchFeedArticles(String url, String source) async {
    try {
      print('Fetching RSS feed from $source at $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Leaff App RSS Reader',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Successfully fetched RSS feed (status: ${response.statusCode})');
        print('Response length: ${response.body.length} bytes');
        
        // Parsing du flux RSS avec xml2json
        final xmlParser = Xml2Json();
        xmlParser.parse(response.body);
        print('XML parsed successfully');
        
        final jsonString = xmlParser.toParker();
        print('JSON conversion successful');
        
        final jsonData = json.decode(jsonString);
        print('JSON parsed successfully');

        return _parseArticles(jsonData, source);
      } else {
        print('Failed to fetch RSS feed (status: ${response.statusCode})');
        throw Exception('Failed to load RSS feed: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error fetching RSS feed from $url: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error fetching RSS feed: $e');
    }
  }

  List<RSSArticle> _parseArticles(Map<String, dynamic> jsonData, String source) {
    List<RSSArticle> articles = [];
    try {
      print('Parsing feed from $source');
      print('JSON data structure: ${jsonData.keys.join(', ')}');
      dynamic items;
      if (jsonData['rss'] != null) {
        jsonData = jsonData['rss'];
      }
      if (jsonData['channel'] != null) {
        jsonData = jsonData['channel'];
      }
      if (jsonData['item'] != null) {
        items = jsonData['item'];
        print('Found items at root level');
      } else if (jsonData['items'] != null) {
        items = jsonData['items'];
        print('Found items in items array');
      } else if (jsonData['entry'] != null) {
        items = jsonData['entry'];
        print('Found entries in Atom format');
      } else if (jsonData['content'] != null && jsonData['content']['item'] != null) {
        items = jsonData['content']['item'];
        print('Found items in content section');
      } else {
        print('No items found in RSS/Atom format');
        print('Raw JSON data: $jsonData');
      }
      if (items != null) {
        print('Processing ${items is List ? items.length : 1} items');
        if (items is List) {
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              final title = item['title'] ?? 'No title';
              final date = item['pubDate'] ?? 'No date';
              print('Processing item: $title');
              print('  Date: $date');
              print('  Raw JSON keys: ${item.keys.join(', ')}');
              articles.add(RSSArticle.fromJson(item, source));
            }
          }
        } else if (items is Map<String, dynamic>) {
          final title = items['title'] ?? 'No title';
          final date = items['pubDate'] ?? 'No date';
          print('Processing single item: $title');
          print('  Date: $date');
          print('  Raw JSON keys: ${items.keys.join(', ')}');
          articles.add(RSSArticle.fromJson(items, source));
        }
      } else {
        print('No items to process');
      }
    } catch (e) {
      print('Error parsing articles from $source: $e');
      print('Stack trace: $e');
    }
    print('Parsed ${articles.length} articles from $source');
    return articles;
  }

  // Cache management methods
  Future<void> _saveToCache(List<RSSArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = articles.map((article) => article.toJson()).toList();
      final jsonString = json.encode(jsonList);
      print('Attempting to save ${articles.length} articles to cache');
      print('Cache data size: ${jsonString.length} characters');
      
      // Check if we can save the data
      if (jsonString.length > 4000000) { // Approximately 4MB limit
        print('Warning: Cache data exceeds 4MB limit, trying to save a smaller subset');
        // Try to save only the most recent articles
        final recentArticles = articles.take(10).toList(); // Save only 10 most recent articles
        final recentJsonList = recentArticles.map((article) => article.toJson()).toList();
        final recentJsonString = json.encode(recentJsonList);
        print('Reduced cache size to: ${recentJsonString.length} characters');
        await prefs.setString(_cacheKey, recentJsonString);
        print('Successfully saved reduced cache with ${recentArticles.length} articles');
      } else {
        await prefs.setString(_cacheKey, jsonString);
        print('Successfully saved ${articles.length} articles to cache');
      }
    } catch (e) {
      print('Error saving to cache: $e');
      if (e.toString().contains('SharedPreferences: Failed to write')) {
        print('Warning: Cache write failed, possibly due to size limit');
      }
    }
  }

  Future<List<RSSArticle>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final jsonList = json.decode(cachedData) as List;
        final articles = jsonList
            .map((json) => RSSArticle.fromCachedJson(json as Map<String, dynamic>))
            .toList();
        
        // Filter out articles older than one week
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        final recentArticles = articles.where((article) {
          return article.pubDate != null && article.pubDate!.isAfter(oneWeekAgo);
        }).toList();
        
        return recentArticles;
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return [];
  }

  Future<void> _updateLastFetchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error updating last fetch time: $e');
    }
  }

  Future<DateTime?> _getLastFetchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastFetchKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
    } catch (e) {
      print('Error getting last fetch time: $e');
    }
    return null;
  }

  Future<void> _performMonthlyCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanupString = prefs.getString(_lastCleanupKey);
      DateTime? lastCleanup;
      
      if (lastCleanupString != null) {
        lastCleanup = DateTime.parse(lastCleanupString);
      }

      final now = DateTime.now();
      
      // Perform cleanup if it's been more than a month since last cleanup
      if (lastCleanup == null || now.difference(lastCleanup).inDays >= 30) {
        print('Performing monthly cache cleanup...');
        
        // Load current cache
        final cachedData = prefs.getString(_cacheKey);
        if (cachedData != null) {
          final jsonList = json.decode(cachedData) as List;
          final articles = jsonList
              .map((json) => RSSArticle.fromCachedJson(json as Map<String, dynamic>))
              .toList();
          
          // Remove articles older than 2 months
          final twoMonthsAgo = now.subtract(const Duration(days: 60));
          final recentArticles = articles.where((article) {
            return article.pubDate != null && article.pubDate!.isAfter(twoMonthsAgo);
          }).toList();
          
          // Save cleaned cache
          final cleanedJsonList = recentArticles.map((article) => article.toJson()).toList();
          await prefs.setString(_cacheKey, json.encode(cleanedJsonList));
          
          print('Cache cleanup completed. Removed ${articles.length - recentArticles.length} old articles');
        }
        
        // Update last cleanup time
        await prefs.setString(_lastCleanupKey, now.toIso8601String());
      }
    } catch (e) {
      print('Error performing monthly cleanup: $e');
    }
  }

  // Clear all cache (useful for debugging or manual refresh)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastFetchKey);
    print('Cache cleared');
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
