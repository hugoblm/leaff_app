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
  final Map<String, String> _assetTypeById = {};
  final List<_CustomAsset> _customAssets = [];
  final List<String> _assetTypeOrder = [];

  PowensService? _powensService;

  @override
  void initState() {
    super.initState();
    // On ne peut pas utiliser Provider.of dans initState, donc on le fait dans didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _powensService ??= Provider.of<PowensService>(context, listen: false);
    _powensService?.addListener(_loadConnectionDetails);
    if (_powensService?.userId != null) {
      _loadConnectionDetails();
      _powensService?.getAccounts().then((_) {
        debugPrint(
            '[BankConnectionsScreen] Comptes bancaires préchargés au démarrage de la page.');
      });
      _powensService?.refreshAllConnectionDetails();
      _loadConnectorsDetails();
    }
  }

  @override
  void dispose() {
    _powensService?.removeListener(_loadConnectionDetails);
    _connectionDetailsList.clear();
    _connectorsByUuid.clear();
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
    debugPrint(
        '[BANK_CONNECTIONS] Chargement mapping connectors, nb: \\${map.length}');
    map.forEach((k, v) => debugPrint(
        '[BANK_CONNECTIONS] connectorUuid: \\${k}, name: \\${v.name}, logo: \\${v.logoUrl}'));
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

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: context.mediumBorderRadius,
        boxShadow: [context.cardShadow],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.onSurfaceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: context.onSurfaceColor,
          ),
        ),
        title: Text(
          title,
          style: context.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: context.bodyMedium.copyWith(
                  color: context.onSurfaceVariantColor,
                ),
              )
            : null,
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.onSurfaceVariantColor,
            ),
      ),
    );
  }

  // Ajoute une fonction utilitaire pour le formatage relatif de la date
  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'il y a moins d\'une minute';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} jours';
    return 'il y a plus d\'une semaine';
  }

  @override
  Widget build(BuildContext context) {
    final powensService = context.watch<PowensService>();
    Widget bodyContent;

    // Regroupement par type d'asset (ordre d'ajout)
    final Map<String, List<BankConnectionDetails>> groupedConnections = {};
    for (final detail in _connectionDetailsList) {
      final type = _assetTypeById[detail.id] ?? 'Checking Account';
      groupedConnections.putIfAbsent(type, () => []).add(detail);
      if (!_assetTypeOrder.contains(type)) _assetTypeOrder.add(type);
    }
    // Ajout des custom assets
    for (final asset in _customAssets) {
      groupedConnections.putIfAbsent(asset.type, () => []);
      if (!_assetTypeOrder.contains(asset.type))
        _assetTypeOrder.add(asset.type);
    }

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
    } else if (_connectionDetailsList.isEmpty && _customAssets.isEmpty) {
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
      bodyContent = ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          for (final type in _assetTypeOrder)
            if ((groupedConnections[type]?.isNotEmpty ?? false) ||
                _customAssets.any((a) => a.type == type)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(type, style: context.titleMedium),
              ),
              // Cartes de banques
              if (groupedConnections[type] != null)
                ...groupedConnections[type]!.map((detail) {
                  final connector =
                      _connectorsByUuid[detail.connectorUuid ?? ''];
                  final bankName =
                      connector?.name ?? detail.bankName ?? 'Banque Inconnue';
                  final lastUpdated = detail.lastUpdate != null
                      ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
                          .format(detail.lastUpdate!)
                      : 'N/A';
                  final isActive = (detail.status == null &&
                      (detail.isActiveFromApi ?? true));
                  final String? logoUrl = detail.connectorUuid != null
                      ? 'https://your-future-cdn.com/logos/${detail.connectorUuid}.png'
                      : null;
                  return _buildSettingsCard(
                    icon: Icons.account_balance,
                    title: bankName,
                    subtitle: 'Mis à jour le : $lastUpdated',
                    onTap: () async {
                      double? bankBalance;
                      // Récupère le solde de la banque depuis le cache (si possible)
                      try {
                        final accounts = await Provider.of<PowensService>(
                                context,
                                listen: false)
                            .getAccounts();
                        final bankAccounts = accounts
                            .where((a) => a.connectionId == detail.id)
                            .toList();
                        bankBalance = bankAccounts.fold(0.0,
                            (sum, acc) => (sum ?? 0.0) + (acc.balance ?? 0.0));
                      } catch (_) {}
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (modalContext) {
                          final double popinHeight =
                              MediaQuery.of(modalContext).size.height * 0.45;
                          return SafeArea(
                            child: Padding(
                              padding: MediaQuery.of(modalContext).viewInsets,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                height: popinHeight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: modalContext.grey300,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        bankName,
                                        style: modalContext.titleLarge,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? modalContext.successBadge.$2
                                              : modalContext.errorBadge.$2,
                                          borderRadius:
                                              modalContext.badgeBorderRadius,
                                        ),
                                        child: Text(
                                          isActive ? 'Actif' : 'Action requise',
                                          style: modalContext.badge.copyWith(
                                              color: isActive
                                                  ? modalContext.successBadge.$1
                                                  : modalContext.errorBadge.$1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      bankBalance != null
                                          ? '${bankBalance.toStringAsFixed(2)} €'
                                          : 'Solde indisponible',
                                      style: modalContext.titleLarge.copyWith(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (detail.lastUpdate != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _formatRelativeDate(
                                              detail.lastUpdate!),
                                          style: modalContext.bodyMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              // TODO: Implémenter la modification
                                              Navigator.of(modalContext).pop();
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.edit,
                                                    color: modalContext
                                                        .primaryColor),
                                                const SizedBox(height: 4),
                                                Text('Modifier',
                                                    style: modalContext
                                                        .bodyMedium
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
                                              // Suppression locale
                                              _connectionDetailsList
                                                  .removeWhere(
                                                      (b) => b.id == detail.id);
                                              _assetTypeById.remove(detail.id);
                                              if (mounted) setState(() {});
                                              Navigator.of(modalContext).pop();
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? context.successBadge.$2
                            : context.errorBadge.$2,
                        borderRadius: context.badgeBorderRadius,
                      ),
                      child: Text(
                        isActive ? 'Actif' : 'Action requise',
                        style: context.badge.copyWith(
                            color: isActive
                                ? context.successBadge.$1
                                : context.errorBadge.$1),
                      ),
                    ),
                  );
                }),
              // Cartes custom assets
              ..._customAssets.where((a) => a.type == type).map((asset) {
                return _buildSettingsCard(
                  icon: Icons.widgets,
                  title: asset.name,
                  subtitle: '',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (modalContext) {
                        final double popinHeight =
                            MediaQuery.of(modalContext).size.height * 0.45;
                        return SafeArea(
                          child: Padding(
                            padding: MediaQuery.of(modalContext).viewInsets,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              height: popinHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: modalContext.grey300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      asset.name,
                                      style: modalContext.titleLarge,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: modalContext.infoBadge.$2,
                                        borderRadius:
                                            modalContext.badgeBorderRadius,
                                      ),
                                      child: Text(
                                        asset.type,
                                        style: modalContext.badge.copyWith(
                                            color: modalContext.infoBadge.$1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Non renseigné',
                                    style: modalContext.titleLarge
                                        .copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            // TODO: Implémenter la modification
                                            Navigator.of(modalContext).pop();
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit,
                                                  color: modalContext
                                                      .primaryColor),
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
                                            _customAssets.removeWhere(
                                                (a) => a.id == asset.id);
                                            if (mounted) setState(() {});
                                            Navigator.of(modalContext).pop();
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
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                );
              }),
            ],
        ],
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
        ],
      ),
      floatingActionButton: powensService.userId != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 8),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.add, color: Colors.white, size: 28),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (modalContext) {
                            final List<_AssetType> assetTypes = [
                              _AssetType('Stocks & Funds', Icons.show_chart),
                              _AssetType('Checking Account',
                                  Icons.account_balance_wallet),
                              _AssetType('Saving Account', Icons.savings),
                              _AssetType('Loans', Icons.request_quote),
                              _AssetType(
                                  'Investment account', Icons.trending_up),
                              _AssetType('Life Insurance', Icons.verified_user),
                              _AssetType('Crypto', Icons.currency_bitcoin),
                              _AssetType('SCPI', Icons.apartment),
                            ];
                            final double popinHeight =
                                MediaQuery.of(modalContext).size.height * 0.45;
                            return SafeArea(
                              child: Padding(
                                padding: MediaQuery.of(modalContext).viewInsets,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  height: popinHeight,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 40,
                                            height: 4,
                                            margin: const EdgeInsets.only(
                                                bottom: 16),
                                            decoration: BoxDecoration(
                                              color: modalContext.grey300,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            'add to my portfolio',
                                            style: modalContext.titleLarge
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            childAspectRatio: 1,
                                          ),
                                          itemCount: assetTypes.length,
                                          itemBuilder: (context, index) {
                                            final asset = assetTypes[index];
                                            return GestureDetector(
                                              onTap: () async {
                                                Navigator.of(modalContext)
                                                    .pop();
                                                if (asset.label ==
                                                    'Checking Account') {
                                                  // Lancer la logique Powens
                                                  final powensService = Provider
                                                      .of<PowensService>(
                                                          context,
                                                          listen: false);
                                                  bool? loginInitiated =
                                                      await powensService
                                                          .login();
                                                  if (loginInitiated == true) {
                                                    debugPrint(
                                                        'BankConnectionsScreen: Ouverture de l\'URL de connexion POWENS...');
                                                    await powensService
                                                        .refreshAllConnectionDetails();
                                                  } else {
                                                    debugPrint(
                                                        'BankConnectionsScreen: Échec de l\'initiation de la connexion POWENS.');
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Impossible d\'initier la connexion bancaire. Assurez-vous d\'être connecté et réessayez.')),
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Coming soon')),
                                                    );
                                                  }
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      modalContext.surfaceColor,
                                                  borderRadius: modalContext
                                                      .mediumBorderRadius,
                                                  boxShadow: [
                                                    modalContext.cardShadow
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(asset.icon,
                                                        size: 44,
                                                        color: modalContext
                                                            .primaryColor),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      asset.label,
                                                      style: modalContext
                                                          .bodyLarge
                                                          .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      tooltip: 'Ajouter un asset',
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// Classe utilitaire pour les assets
class _AssetType {
  final String label;
  final IconData icon;
  const _AssetType(this.label, this.icon);
}

// Classe pour les assets non bancaires
class _CustomAsset {
  final String id;
  final String name;
  final String type;
  _CustomAsset({required this.id, required this.name, required this.type});
}
