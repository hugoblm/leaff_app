import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:leaff_app/widgets/text_utils.dart';
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(cleanRssText(article.title)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
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
                    cleanRssText(article.title),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Source et date
                  Row(
                    children: [
                      Text(
                        article.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ) ?? const TextStyle(fontSize: 12),
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
                      cleanRssText(article.content!),
                      textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ) ?? const TextStyle(fontSize: 16),
                      onTapUrl: (url) async {
                        _launchURL(url);
                        return false;
                      },
                    )
                  else
                    Text(
                      cleanRssText(article.description),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ) ?? const TextStyle(fontSize: 16),
                    ),
                  
                  // Bouton pour ouvrir l'article original
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(56.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _launchURL(article.link),
                      icon: const Icon(Icons.newspaper_rounded, size: 20, color: Colors.white),
                      label: const Text('Lire l\'article'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
