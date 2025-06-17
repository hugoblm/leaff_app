import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:leaff_app/widgets/text_utils.dart';
import 'package:leaff_app/services/rss_service.dart';
import 'package:leaff_app/screens/article_screen.dart';

class EcoNewsScreen extends StatefulWidget {
  final void Function(ScrollController)? scrollControllerCallback;
  const EcoNewsScreen({Key? key, this.scrollControllerCallback}) : super(key: key);

  @override
  State<EcoNewsScreen> createState() => _EcoNewsScreenState();
}

class _EcoNewsScreenState extends State<EcoNewsScreen> {
  List<RSSArticle> _articles = [];
  bool _isLoadingArticles = true;
  String? _errorMessage;
  bool _initialized = false;

  late RSSService _rssService;
  late final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _rssService = Provider.of<RSSService>(context, listen: false);
      _loadArticles();
      if (widget.scrollControllerCallback != null) {
        widget.scrollControllerCallback!(_scrollController);
      }
      _initialized = true;
    }
  }

  Future<void> _loadArticles({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoadingArticles = true;
        _errorMessage = null;
      });
      final articles = await _rssService.fetchAllArticles(forceRefresh: forceRefresh);
      setState(() {
        _articles = articles;
        _isLoadingArticles = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des articles: $e';
        _isLoadingArticles = false;
      });
    }
  }

  Future<void> _refreshArticles() async {
    await _loadArticles(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco, size: 32, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Text(
                'Good Ecological News',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isLoadingArticles)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (!_isLoadingArticles && _articles.isNotEmpty)
                Text(
                  '${_articles.length} articles',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ) ?? const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Expanded(
          child: _articles.isEmpty && !_isLoadingArticles
              ? const Center(child: Text('Aucun article disponible'))
              : RefreshIndicator(
                  onRefresh: _refreshArticles,
                  color: Colors.transparent, // loader natif invisible
                  displacement: 0.1, // déplacement minimal
                  notificationPredicate: (notification) => notification.depth == 0,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      final formattedDate = article.pubDate != null
                          ? DateFormat('dd MMM yyyy').format(article.pubDate!)
                          : 'Date inconnue';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArticleScreen(article: article),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        article.categoryEmoji,
                                        style: const TextStyle(fontSize: 30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                article.category,
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          cleanRssText(article.title),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF212529),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cleanRssText(article.description),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
