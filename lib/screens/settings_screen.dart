import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Connexion à la banque', style: TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connexion à la banque (Tink) à venir')),
              );
            },
            child: const Text('Ajouter ma banque'),
          ),
          const SizedBox(height: 24),
          const Text('Adresse', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            decoration: const InputDecoration(hintText: 'Votre adresse'),
          ),
          const SizedBox(height: 24),
          const Text('Habitudes de consommation', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            decoration: const InputDecoration(hintText: 'Ex : végétarien, vélo, etc.'),
          ),
          const SizedBox(height: 24),
          const Text('Préférences', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: true,
            onChanged: (v) {},
            title: const Text('Recevoir des notifications positives'),
          ),
        ],
      ),
    );
  }
}
