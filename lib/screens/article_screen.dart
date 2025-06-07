import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/rss_service.dart';

class ArticleScreen extends StatefulWidget {
  final RSSArticle article;

  const ArticleScreen({Key? key, required this.article}) : super(key: key);

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  // Les champs _isLoading et _errorMessage ne sont plus nécessaires
  // car on utilise directement le contenu du flux RSS

  @override
  void initState() {
    super.initState();
  }

  // Fonction pour ouvrir les liens dans le navigateur
  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'article
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.network(
                  article.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            
            // Contenu de l'article
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    article.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Source et date
                  Row(
                    children: [
                      Text(
                        article.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article.pubDate != null
                            ? DateFormat('dd/MM/yyyy à HH:mm').format(article.pubDate!)
                            : 'Date inconnue',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contenu de l'article
                  if (article.content != null && article.content!.isNotEmpty)
                    HtmlWidget(
                      article.content!,
                      textStyle: theme.textTheme.bodyLarge,
                      onTapUrl: (url) async {
                        _launchURL(url);
                        return false;
                      },
                    )
                  else
                    Text(
                      article.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                  
                  // Bouton pour ouvrir l'article original
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchURL(article.link),
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('Lire l\'article original'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
