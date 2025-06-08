import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/powens_service.dart';
import '../widgets/leaff_appbar.dart';
import '../widgets/leaff_card.dart';

class BankConnectionScreen extends StatefulWidget {
  const BankConnectionScreen({super.key});

  @override
  State<BankConnectionScreen> createState() => _BankConnectionScreenState();
}

class _BankConnectionScreenState extends State<BankConnectionScreen> {
  bool _isLoading = false;
  List<dynamic>? _banks;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Dans une application réelle, vous récupéreriez cette liste depuis l'API POWENS
      // Pour l'instant, nous utilisons une liste factice
      await Future.delayed(const Duration(seconds: 1)); // Simulation de chargement
      
      setState(() {
        _banks = [
          {
            'id': 'societe_generale',
            'name': 'Société Générale',
            'logo': 'https://upload.wikimedia.org/wikipedia/fr/3/3f/Logo_Societe_Generale.png',
          },
          {
            'id': 'bnp_paribas',
            'name': 'BNP Paribas',
            'logo': 'https://upload.wikimedia.org/wikipedia/fr/thumb/3/3d/Logo_BNP_Paribas.svg/1200px-Logo_BNP_Paribas.svg.png',
          },
          {
            'id': 'credit_agricole',
            'name': 'Crédit Agricole',
            'logo': 'https://upload.wikimedia.org/wikipedia/fr/0/0d/Logo_Cr%C3%A9dit_Agricole.svg',
          },
          {
            'id': 'banque_populaire',
            'name': 'Banque Populaire',
            'logo': 'https://upload.wikimedia.org/wikipedia/fr/3/3b/Banque_Populaire_logo_2019.png',
          },
          {
            'id': 'caisse_epargne',
            'name': 'Caisse d\'Épargne',
            'logo': 'https://upload.wikimedia.org/wikipedia/fr/1/1d/Logo_Groupe_BPCE.png',
          },
        ];
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des banques: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToBank(String bankId) async {
    final powensService = context.read<PowensService>();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await powensService.login();
      if (!success) {
        throw Exception('Impossible de lancer le processus de connexion');
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la connexion à la banque: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LeaffAppBar(
        title: 'Connecter une banque',
        showBackButton: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _banks == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBanks,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_banks == null || _banks!.isEmpty) {
      return const Center(
        child: Text('Aucune banque disponible pour le moment'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _banks!.length,
      itemBuilder: (context, index) {
        final bank = _banks![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LeaffCard(
            onTap: () => _connectToBank(bank['id']),
            child: ListTile(
              leading: bank['logo'] != null
                  ? Image.network(
                      bank['logo'],
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.account_balance, size: 40),
                    )
                  : const Icon(Icons.account_balance, size: 40),
              title: Text(
                bank['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        );
      },
    );
  }
}
