import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/rss_service.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';
import './article_screen.dart'; // Ajout de l'import pour ArticleScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  List<RSSArticle> _articles = [];
  bool _isLoadingArticles = true;
  String? _errorMessage;

  late final RSSService _rssService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rssService = Provider.of<RSSService>(context, listen: false);
    _loadUserInfo();
    _loadArticles();
    // Nettoyer le cache et forcer le rafraîchissement
    _rssService.clearCache();
    _loadArticles(forceRefresh: true);
  }

  void _loadUserInfo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      setState(() {
        _user = authService.getUserInfo();
      });
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshArticles,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${_user?.displayName ?? 'User'}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF212529),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome to Leaff',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          _user?.photoURL != null && _user!.photoURL!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage(_user!.photoURL!),
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundColor: const Color(0xFF212529),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Good Ecological News',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF212529),
                            ),
                          ),
                          Row(
                            children: [
                              if (_isLoadingArticles)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              if (!_isLoadingArticles && _articles.isNotEmpty)
                                Text(
                                  '${_articles.length} articles récents',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_articles.isEmpty && !_isLoadingArticles) {
                        return const Center(
                          child: Text('Aucun article disponible'),
                        );
                      }
                      if (index >= _articles.length) return null;
                      return _buildNewsCard(context, _articles[index]);
                    },
                    childCount: _articles.isEmpty ? 1 : _articles.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, RSSArticle article) {
    final dateFormatter = DateFormat('dd MMM yyyy');
    final formattedDate = article.pubDate != null 
        ? dateFormatter.format(article.pubDate!) 
        : 'Date inconnue';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: const Color(0xFF212529).withValues(alpha: 0.1),
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
                              color: Colors.green.withValues(alpha: 0.1),
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
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
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
                        article.description,
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
  }
}
