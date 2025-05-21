import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final news = [
      {
        'title': 'La France dépasse ses objectifs de réduction de CO2 en 2024',
        'summary': 'Les émissions de gaz à effet de serre ont baissé de 8% cette année.'
      },
      {
        'title': 'Une nouvelle forêt urbaine plantée à Lyon',
        'summary': 'Plus de 10 000 arbres plantés pour rafraîchir la ville.'
      },
      {
        'title': 'Le solaire devient la première source d\'énergie en Europe',
        'summary': 'Une étape historique pour la transition énergétique.'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Actualités positives')),
      body: ListView.builder(
        itemCount: news.length,
        itemBuilder: (context, index) {
          final item = news[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(item['title']!),
              subtitle: Text(item['summary']!),
              leading: const Icon(Icons.eco, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
