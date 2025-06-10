import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/powens_service.dart';
import '../models/bank_connection_details_model.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class BankConnectionsScreen extends StatefulWidget {
  const BankConnectionsScreen({super.key});

  @override
  State<BankConnectionsScreen> createState() => _BankConnectionsScreenState();
}

class _BankConnectionsScreenState extends State<BankConnectionsScreen> {
  List<BankConnectionDetails> _connectionDetailsList = [];
  bool _isLoadingDetails = false; // Initialisé à false, car on charge seulement si userId est là
  bool _isInitializingPowensUser = false;
  bool _hasLoadingError = false;
  int _loadAttempts = 0;
  final int _maxLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    // Ajout de l'écouteur pour le rafraîchissement automatique
    Provider.of<PowensService>(context, listen: false).addListener(_loadConnectionDetails);
    final powensService = Provider.of<PowensService>(context, listen: false);
    // Si l'userId Powens est déjà disponible (chargé depuis le stockage sécurisé),
    // on charge les détails des connexions.
    if (powensService.userId != null) {
      _loadConnectionDetails();
    } 
    // Sinon, la méthode build() affichera l'option pour initialiser l'utilisateur Powens.
  }

  @override
  void dispose() {
    // Suppression de l'écouteur pour éviter les fuites de mémoire
    Provider.of<PowensService>(context, listen: false).removeListener(_loadConnectionDetails);
    super.dispose();
  }

  Future<void> _initializePowensUser() async {
    debugPrint('BankConnectionsScreen: _initializePowensUser CALLED');
    if (!mounted) return;
    setState(() {
      _isInitializingPowensUser = true;
      _hasLoadingError = false; // Réinitialiser l'erreur potentielle
    });

    final powensService = Provider.of<PowensService>(context, listen: false);
    final String? powensUserId = await powensService.initializePowensUserAndGetId();

    if (!mounted) return;

    if (powensUserId != null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.savePowensUserId(powensUserId);
      debugPrint('BankConnectionsScreen: Utilisateur Powens initialisé avec ID: $powensUserId et sauvegardé dans Firebase.');
      // Maintenant que userId est disponible, charger les connexions
      _loadConnectionDetails(); 
    } else {
      debugPrint('BankConnectionsScreen: Échec de l''initialisation de l''utilisateur Powens.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d''activer la connexion bancaire. Veuillez réessayer.')),
        );
        setState(() {
          _hasLoadingError = true; // Indiquer une erreur générale pour l'initialisation
        });
      }
    }
    setState(() {
      _isInitializingPowensUser = false;
    });
  }

  Future<void> _loadConnectionDetails() async {
    if (!mounted) return;
    if (_loadAttempts >= _maxLoadAttempts) {
      debugPrint('BankConnectionsScreen: Nombre maximum de tentatives de chargement atteint.');
      setState(() {
        _isLoadingDetails = false;
        _hasLoadingError = true; 
      });
      return;
    }

    final powensService = Provider.of<PowensService>(context, listen: false);
    if (powensService.userId == null) {
      debugPrint('BankConnectionsScreen: Tentative de chargement des détails sans Powens User ID.');
      // Normalement, cela ne devrait pas arriver si la logique de build est correcte.
      setState(() {
        _isLoadingDetails = false;
        _hasLoadingError = true; // Ou un état spécifique
      });
      return;
    }

    setState(() {
      _isLoadingDetails = true;
      _hasLoadingError = false;
      _connectionDetailsList.clear();
    });
    _loadAttempts++;
    
    List<BankConnectionDetails> detailsList = [];
    // D'abord, récupérer la liste des IDs de connexion via l'API
    final List<String> connectionIdsFromApi = await powensService.listUserConnections();

    if (!mounted) return;

    if (connectionIdsFromApi.isNotEmpty) {
      for (String id in connectionIdsFromApi) {
        final detail = await powensService.getConnectionDetails(id);
        if (detail != null) {
          detailsList.add(detail);
        }
      }
    } else {
      debugPrint('BankConnectionsScreen: Aucune connexion retournée par listUserConnections.');
    }

    if (!mounted) return;
    setState(() {
      _connectionDetailsList = detailsList;
      _isLoadingDetails = false;
      // Si la liste est vide après chargement réussi, ce n'est pas une erreur en soi.
      // _hasLoadingError reste false si l'API a répondu correctement.
    });
  }


  Widget _buildReusableCard({
    required Widget leading,
    required String title,
    String? subtitle,
    String? badgeText,
    Color? badgeBackgroundColor,
    Color? badgeTextColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: context.mediumBorderRadius,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: leading,
        title: Text(
          title,
          style: context.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: context.bodyMedium.copyWith(
                  color: context.onSurfaceVariantColor,
                ),
              ),
            ],
            if (badgeText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBackgroundColor ?? Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor ?? Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.onSurfaceVariantColor,
            ),
      ),
    );
  }

  // L'ancienne méthode _buildBankConnectionCard est maintenant adaptée pour utiliser le widget réutilisable
  Widget _buildBankConnectionCard({
    required String bankName,
    required String lastUpdated,
    required bool isActive,
    String? logoUrl,
    VoidCallback? onTap,
  }) {
    final leadingWidget = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: logoUrl != null && logoUrl.isNotEmpty
              ? Image.network(
                logoUrl,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.account_balance, color: Theme.of(context).colorScheme.onSurface),
              )
            : Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.onSurface,
              ),
      ),
    );

    String badgeText;
    Color badgeBackgroundColor;
    Color badgeTextColor;

    if (isActive) {
      badgeText = 'Actif';
      badgeBackgroundColor = Colors.green.withOpacity(0.1);
      badgeTextColor =  Colors.green;
    } else {
      badgeText = 'Action requise';
      badgeBackgroundColor = Colors.orange.withOpacity(0.1);
      badgeTextColor = Colors.orange;
    }

    return _buildReusableCard(
      leading: leadingWidget,
      title: bankName,
      subtitle: 'Mis à jour le : $lastUpdated',
      badgeText: badgeText,
      badgeBackgroundColor: badgeBackgroundColor,
      badgeTextColor: badgeTextColor,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser context.watch pour réagir aux changements d'état de PowensService (userId, etc.)
    final powensService = context.watch<PowensService>();

    Widget bodyContent;

    if (_isInitializingPowensUser) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (powensService.userId == null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync_problem, size: 60, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              const Text(
                'Connexion bancaire non activée',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Pour visualiser vos connexions bancaires et ajouter de nouvelles banques, veuillez d\'abord activer la synchronisation sécurisée avec Powens.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Activer la connexion bancaire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF366444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _initializePowensUser,
              ),
              if (_hasLoadingError) ...[
                const SizedBox(height: 15),
                Text(
                  'Une erreur est survenue. Veuillez réessayer. ', 
                  style: TextStyle(color: Theme.of(context).colorScheme.error)
                ),
              ]
            ],
          ),
        ),
      );
    } else if (_isLoadingDetails) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_hasLoadingError) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text('Erreur de chargement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Impossible de charger les détails de vos connexions bancaires.'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: () {
                _loadAttempts = 0; // Réinitialiser les tentatives
                _loadConnectionDetails();
              },
            ),
          ],
        ),
      );
    } else if (_connectionDetailsList.isEmpty) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 60, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text('Aucune connexion bancaire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Vous n\'avez pas encore de connexion bancaire active.'),
            // Le bouton "Ajouter une nouvelle banque" sera en dehors de ce bodyContent, en bas.
          ],
        ),
      );
    } else {
      bodyContent = ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _connectionDetailsList.length,
        itemBuilder: (context, index) {
          final detail = _connectionDetailsList[index];
          final bankName = detail.connectorName ?? detail.bankName ?? 'Banque Inconnue';
          final lastUpdated = detail.lastUpdate != null
              ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(detail.lastUpdate!)
              : 'N/A';
          final isActive = (detail.status == null && (detail.isActiveFromApi ?? true));

          // Préparation pour le futur CDN : construire l'URL du logo avec l'UUID du connecteur
          // TODO: Remplacer 'https://your-future-cdn.com/logos' par l'URL de base de votre CDN
          final String? logoUrl = detail.connectorUuid != null
              ? 'https://your-future-cdn.com/logos/${detail.connectorUuid}.png'
              : null;

          return _buildBankConnectionCard(
            bankName: bankName,
            lastUpdated: lastUpdated,
            isActive: isActive,
            logoUrl: logoUrl, // Utiliser l'URL construite
            onTap: () {
              print('Tapped on bank: ${detail.id} - ${detail.bankName}');
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mes Connexions Bancaires',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // Personnalisation de la couleur du bouton de retour
        iconTheme: IconThemeData(
          color: context.onSurfaceVariantColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(child: bodyContent),
          // Le bouton "Ajouter une nouvelle banque" ne s'affiche que si l'utilisateur Powens est initialisé
          if (powensService.userId != null) 
            Padding(
              padding: const EdgeInsets.all(56.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Ajouter une nouvelle banque'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: context.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  // powensService est déjà récupéré avec context.watch en haut de build()
                  bool? loginInitiated = await powensService.login();
                  if (loginInitiated == true) {
                    print('BankConnectionsScreen: Ouverture de l''URL de connexion POWENS...');
                  } else {
                    print('BankConnectionsScreen: Échec de l''initiation de la connexion POWENS.');
                    if (mounted) { // 'context' est disponible ici car nous sommes dans build()
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Impossible d''initier la connexion bancaire. Assurez-vous d''être connecté et réessayez.')),
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
