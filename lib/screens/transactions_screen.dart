import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'label': 'Achat supermarché',
        'amount': 54.90,
        'date': '2024-05-20',
        'score': 7,
        'details': 'Alimentation conventionnelle',
        'recommendation': 'Privilégier les produits locaux et bio'
      },
      {
        'label': 'Train Paris-Lyon',
        'amount': 32.00,
        'date': '2024-05-18',
        'score': 2,
        'details': 'Transport bas carbone',
        'recommendation': 'Bravo, le train est une excellente option !'
      },
      {
        'label': 'Essence voiture',
        'amount': 60.00,
        'date': '2024-05-15',
        'score': 9,
        'details': 'Transport individuel fossile',
        'recommendation': 'Privilégier le covoiturage ou les transports en commun'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mes dépenses & score carbone')),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('${tx['label']} - ${tx['amount']} €'),
              subtitle: Text('${tx['date']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100 * (10 - (tx['score'] as int))],
                    child: Text('${tx['score']}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Détail de la note'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Détail : ${tx['details']}'),
                              const SizedBox(height: 8),
                              Text('Recommandation : ${tx['recommendation']}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
