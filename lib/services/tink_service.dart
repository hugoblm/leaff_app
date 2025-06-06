import 'dart:async';

class TinkService {
  // Simule la connexion à une banque (POC)
  Future<bool> connectBank() async {
    await Future.delayed(const Duration(seconds: 1));
    // Toujours succès pour le POC
    return true;
  }

  // Simule la récupération de transactions (POC)
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
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
  }
}

