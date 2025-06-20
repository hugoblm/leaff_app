import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/powens_service.dart';
import '../models/account_details_model.dart';
import '../models/bank_connection_details_model.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/connector_details_model.dart';
import '../services/carbon_score_cache_service.dart';
import '../services/rss_cache_service.dart';

// Pour injecter le Provider balance, utilisez :
// MaterialPageRoute(builder: (_) => const BankConnectionsScreenWrapper()),

class BankConnectionsScreen extends StatefulWidget {
  const BankConnectionsScreen({super.key});

  @override
  State<BankConnectionsScreen> createState() => _BankConnectionsScreenState();
}

class BankConnectionsScreenWrapper extends StatelessWidget {
  const BankConnectionsScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureProvider<List<AccountDetails>>(
      create: (_) =>
          Provider.of<PowensService>(context, listen: false).getAccounts(),
      initialData: const [],
      child: const BankConnectionsScreen(),
    );
  }
}

class _BankConnectionsScreenState extends State<BankConnectionsScreen> {
  List<BankConnectionDetails> _connectionDetailsList = [];
  final Map<String, ConnectorDetails> _connectorsByUuid = {};
  bool _isLoadingDetails = false;
  bool _isInitializingPowensUser = false;
  bool _hasLoadingError = false;
  int _loadAttempts = 0;
  final int _maxLoadAttempts = 3;

  @override
  void initState() {
    super.initState();
    Provider.of<PowensService>(context, listen: false)
        .addListener(_loadConnectionDetails);
    final powensService = Provider.of<PowensService>(context, listen: false);
    if (powensService.userId != null) {
      _loadConnectionDetails();
      powensService.getAccounts().then((_) {
        debugPrint('[BankConnectionsScreen] Comptes bancaires préchargés au démarrage de la page.');
      });
      powensService.refreshAllConnectionDetails();
      _loadConnectorsDetails();
    }
  }

  @override
  void dispose() {
    Provider.of<PowensService>(context, listen: false)
        .removeListener(_loadConnectionDetails);
    super.dispose();
  }

  Future<void> _initializePowensUser() async {
    debugPrint('BankConnectionsScreen: _initializePowensUser CALLED');
    if (!mounted) return;
    setState(() {
      _isInitializingPowensUser = true;
      _hasLoadingError = false;
    });

    final powensService = Provider.of<PowensService>(context, listen: false);
    final String? powensUserId =
        await powensService.initializePowensUserAndGetId();

    if (!mounted) return;

    if (powensUserId != null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.savePowensUserId(powensUserId);
      debugPrint(
          'BankConnectionsScreen: Utilisateur Powens initialisé avec ID: $powensUserId et sauvegardé dans Firebase.');
      _loadConnectionDetails();
    } else {
      debugPrint('BankConnectionsScreen: Échec de l'
          'initialisation de l'
          'utilisateur Powens.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible d'
                  'activer la connexion bancaire. Veuillez réessayer.')),
        );
        setState(() {
          _hasLoadingError = true;
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
      debugPrint(
          'BankConnectionsScreen: Nombre maximum de tentatives de chargement atteint.');
      setState(() {
        _isLoadingDetails = false;
        _hasLoadingError = true;
      });
      return;
    }

    final powensService = Provider.of<PowensService>(context, listen: false);
    if (powensService.userId == null) {
      debugPrint(
          'BankConnectionsScreen: Tentative de chargement des détails sans Powens User ID.');
      setState(() {
        _isLoadingDetails = false;
        _hasLoadingError = true;
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
    final List<String> connectionIdsFromApi =
        await powensService.listUserConnections();

    if (!mounted) return;

    if (connectionIdsFromApi.isNotEmpty) {
      for (String id in connectionIdsFromApi) {
        final detail = await powensService.getConnectionDetails(id);
        if (detail != null) {
          detailsList.add(detail);
        }
      }
    } else {
      debugPrint(
          'BankConnectionsScreen: Aucune connexion retournée par listUserConnections.');
    }

    if (!mounted) return;
    setState(() {
      _connectionDetailsList = detailsList;
      _isLoadingDetails = false;
    });
  }

  Future<void> _loadConnectorsDetails() async {
    final powensService = Provider.of<PowensService>(context, listen: false);
    final map = await powensService.loadAllConnectorDetails();
    debugPrint('[BANK_CONNECTIONS] Chargement mapping connectors, nb: \\${map.length}');
    map.forEach((k, v) => debugPrint('[BANK_CONNECTIONS] connectorUuid: \\${k}, name: \\${v.name}, logo: \\${v.logoUrl}'));
    if (!mounted) return;
    setState(() {
      _connectorsByUuid.clear();
      _connectorsByUuid.addAll(map);
    });
  }

  Future<void> _clearAllAppCaches() async {
    // Purge Powens (détails, connecteurs, auth)
    final powensService = Provider.of<PowensService>(context, listen: false);
    await powensService.clearAllLocalData();
    // Purge RSS
    await RssCacheService.clearCache();
    // Purge scores carbone
    final carbonScoreCache = await CarbonScoreCacheService.getInstance();
    await carbonScoreCache.clearAllScores();
    debugPrint('Tous les caches applicatifs ont été purgés.');
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                  borderRadius: context.badgeBorderRadius,
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

  Widget _buildBankConnectionCard({
    required String connectorUuid,
    required String lastUpdated,
    required bool isActive,
    String? logoUrl,
    VoidCallback? onTap,
  }) {
    final connector = _connectorsByUuid[connectorUuid];
    final bankName = connector?.name ?? 'Banque Inconnue';
    debugPrint('[BANK_CONNECTIONS] build card connectorUuid: \\${connectorUuid}, bankName: \\${bankName}, connector: \\${connector?.toJson()}');
    final leadingWidget = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.grey100,
        borderRadius: context.badgeBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: context.badgeBorderRadius,
        child: logoUrl != null && logoUrl.isNotEmpty
            ? Image.network(
                logoUrl,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_balance,
                    color: Theme.of(context).colorScheme.onSurface),
              )
            : Icon(
                Icons.account_balance,
                color: Theme.of(context).colorScheme.onSurface,
              ),
      ),
    );

    return _buildReusableCard(
      leading: leadingWidget,
      title: bankName,
      subtitle: 'Mis à jour le : $lastUpdated',
      badgeText: isActive ? 'Actif' : 'Action requise',
      badgeBackgroundColor: isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
      badgeTextColor: isActive ? Colors.green : Colors.orange,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.sync_problem,
                  size: 60, color: Colors.orangeAccent),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _initializePowensUser,
              ),
              if (_hasLoadingError) ...[
                const SizedBox(height: 15),
                Text('Une erreur est survenue. Veuillez réessayer. ',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
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
            const Text('Erreur de chargement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                'Impossible de charger les détails de vos connexions bancaires.'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              onPressed: () {
                _loadAttempts = 0;
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
            const Text('Aucune connexion bancaire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Vous n\'avez pas encore de connexion bancaire active.'),
          ],
        ),
      );
    } else {
      bodyContent = ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _connectionDetailsList.length,
        itemBuilder: (context, index) {
          // Ce 'context' (de itemBuilder) A ACCÈS au Provider
          final detail = _connectionDetailsList[index];
          final bankName =
              detail.connectorName ?? detail.bankName ?? 'Banque Inconnue';
          final lastUpdated = detail.lastUpdate != null
              ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                  .format(detail.lastUpdate!)
              : 'N/A';
          final isActive =
              (detail.status == null && (detail.isActiveFromApi ?? true));
          final String? logoUrl = detail.connectorUuid != null
              ? 'https://your-future-cdn.com/logos/${detail.connectorUuid}.png'
              : null;

          return _buildBankConnectionCard(
            connectorUuid: detail.connectorUuid ?? '',
            lastUpdated: lastUpdated,
            isActive: isActive,
            logoUrl: logoUrl,
            onTap: () {
              // *** MODIFICATION ICI ***
              // Récupérer List<AccountDetails> EN UTILISANT LE CONTEXTE DE ITEMBUILDER (qui a accès)
              final List<AccountDetails> resolvedAccounts =
                  Provider.of<List<AccountDetails>>(context, listen: false);
              debugPrint(
                  '[POPIN SOLDE PRE-FETCH] Comptes récupérés avant modal: ${resolvedAccounts.length}');

              showModalBottomSheet(
                context:
                    context, // Utilisation du contexte de itemBuilder pour lancer le modal
                isScrollControlled: true,
                enableDrag: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (modalContext) {
                  // modalContext est pour le contenu du BottomSheet
                  return Padding(
                    padding: MediaQuery.of(modalContext).viewInsets,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(detail.bankName ?? 'Banque',
                              style: modalContext.titleLarge),
                          // BADGE STATUS
                          if (detail.status != null || (detail.status == null && (detail.isActiveFromApi ?? true)))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (detail.status == null || detail.status == 'active')
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: modalContext.badgeBorderRadius,
                                ),
                                child: Text(
                                  detail.status == null || detail.status == 'active'
                                      ? 'Actif'
                                      : detail.status!,
                                  style: TextStyle(
                                    color: (detail.status == null || detail.status == 'active')
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          // *** MODIFICATION ICI ***
                          // Utiliser 'resolvedAccounts' directement au lieu de Provider.of(modalContext, ...)
                          (() {
                            // On récupère la liste des comptes injectée par le FutureProvider
                            final List<AccountDetails> resolvedAccounts = Provider.of<List<AccountDetails>>(context, listen: false);
                            
                            if (resolvedAccounts.isEmpty) {
                              // Affiche un loader si la liste est vide (chargement en cours)
                              return const Padding(
                                padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final bankAccounts = resolvedAccounts.where((a) => a.connectionId == detail.id).toList();
                            final totalBalance = bankAccounts.fold(0.0, (sum, acc) => sum + acc.balance);
                            final formattedBalance = NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(totalBalance);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                              child: Text(
                                ' $formattedBalance',
                                style: modalContext.titleLarge.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            );
                          })(),
                          if (detail.lastUpdate != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                'Dernière mise à jour le : ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(detail.lastUpdate!)}',
                                style: modalContext.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    // Optionnel: InkWell pour l'effet de feedback
                                    onTap: () {
                                      // TODO: Implémenter la modification
                                      Navigator.of(modalContext)
                                          .pop(); // Fermer le modal après action
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit,
                                            color: modalContext.primaryColor),
                                        const SizedBox(height: 4),
                                        Text('Modifier',
                                            style: modalContext.bodyMedium
                                                .copyWith(
                                                    color: modalContext
                                                        .primaryColor)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () async {
                                      final powensService = Provider.of<PowensService>(context, listen: false);
                                      final connectionIdToDelete = detail.id;
                                      bool success = false;

                                      // Effectuer la suppression
                                      if (mounted) {
                                        success = await powensService.deleteConnection(connectionIdToDelete);
                                      }

                                      // Mettre à jour l'UI et fermer le modal SEULEMENT si le widget est toujours monté
                                      if (mounted) {
                                        if (success) {
                                          // Nettoyer les scores carbone liés à cette connexion
                                          final accounts = await powensService.getAccounts();
                                          final accountIds = accounts.where((a) => a.connectionId == connectionIdToDelete).map((a) => a.id).toList();
                                          // Si tu as un cache local de transactions, récupère les transactions de ces comptes
                                          // Ici, on suppose que tu peux récupérer les transactions depuis l'API ou localement
                                          // TODO: Remplacer par la récupération locale si tu ajoutes un cache local
                                          List<String> transactionIds = [];
                                          // ... code pour remplir transactionIds à partir des transactions liées à accountIds ...
                                          final carbonScoreCache = await CarbonScoreCacheService.getInstance();
                                          await carbonScoreCache.clearScoresForConnection(transactionIds);
                                        }
                                        final SnackBar snackBar = success
                                            ? const SnackBar(content: Text('Connexion bancaire supprimée.'))
                                            : const SnackBar(content: Text('Erreur lors de la suppression de la connexion.'));

                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                          }
                                        });

                                        if (success) {
                                          await _loadConnectionDetails();
                                          await _loadConnectorsDetails();
                                        }
                                        Navigator.of(modalContext).pop();
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        SizedBox(height: 4),
                                        Text('Supprimer',
                                            style: TextStyle(
                                                color: Colors.red)),
                                      ],
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
                },
              );
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
        iconTheme: IconThemeData(
          color: context.onSurfaceVariantColor,
        ),
      ),
      body: Column(
        children: [
          Expanded(child: bodyContent),
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
                    borderRadius: context.badgeBorderRadius,
                  ),
                ),
                onPressed: () async {
                  bool? loginInitiated = await powensService.login();
                  if (loginInitiated == true) {
                    debugPrint('BankConnectionsScreen: Ouverture de l'
                        'URL de connexion POWENS...');
                    await powensService.refreshAllConnectionDetails();
                  } else {
                    debugPrint('BankConnectionsScreen: Échec de l'
                        'initiation de la connexion POWENS.');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Impossible d'
                                'initier la connexion bancaire. Assurez-vous d'
                                'être connecté et réessayez.')),
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
