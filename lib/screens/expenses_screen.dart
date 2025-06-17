import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_details_model.dart';
import '../models/account_details_model.dart';
import '../models/bank_connection_details_model.dart';
import '../services/powens_service.dart';
import '../theme/app_theme.dart';
import 'package:leaff_app/services/carbon_score_cache_service.dart';
import 'package:leaff_app/services/climatiq_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/connector_details_model.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final Map<String, double?> _carbonScores =
      {}; // id transaction -> score carbone
  final Map<String, BankConnectionDetails> _connectionsById =
      {}; // mapping persistant
  final Map<String, AccountDetails> _accountsById =
      {}; // mapping accountId -> connectionId
  final Map<String, ConnectorDetails> _connectorsByUuid =
      {}; // nouveau mapping connectorUuid -> details
  int _bankCount = 0; // For badge logic

  Future<void> _loadCarbonScoresForTransactions(
      List<TransactionDetails> transactions) async {
    // Charger le cache persistant
    final cache = await CarbonScoreCacheService.getInstance();
    final List<Map<String, dynamic>> batchToFetch = [];
    for (final tx in transactions) {
      // Si le score est déjà en mémoire, on skip
      if (_carbonScores.containsKey(tx.id)) continue;
      // Sinon on tente le cache persistant
      final cached = await cache.getScore(tx.id);
      if (cached != null) {
        _carbonScores[tx.id] = cached;
      } else {
        batchToFetch.add({
          'id': tx.id,
          'amount': tx.amount.abs(), // montant absolu
          'currency':
              'eur', // fallback, à remplacer par tx.currency quand dispo
        });
      }
    }
    // Batchs de 5 transactions max
    if (batchToFetch.isNotEmpty) {
      final apiKey = dotenv.env['CLIMATIQ_API_KEY'] ?? '';
      final climatiq = ClimatiqService(apiKey: apiKey);
      const int batchSize = 5;
      for (var i = 0; i < batchToFetch.length; i += batchSize) {
        final subBatch = batchToFetch.sublist(
            i,
            (i + batchSize > batchToFetch.length)
                ? batchToFetch.length
                : i + batchSize);
        final batchResults = await climatiq.estimateCarbonBatch(subBatch);
        // Debug mapping retour
        for (var idx = 0; idx < subBatch.length; idx++) {
          final txId = subBatch[idx]['id'].toString();
          final mappedValue = batchResults[txId];
          debugPrint('[ExpensesScreen] Mapping batch retour idx:$idx txId:$txId => $mappedValue');
          _carbonScores[txId] = mappedValue;
          if (mappedValue != null) {
            await cache.setScore(txId, mappedValue);
          }
        }
        if (mounted) setState(() {});
      }
    }
  }

  final List<TransactionDetails> _transactions = [];
  final Map<DateTime, List<TransactionDetails>> _groupedTransactions = {};
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _nextPageUrl;
  bool _hasMore = true;
  String? _error;

  double? _totalBalance;
  bool _isBalanceLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchInitialData();
    _loadConnectionsDetails(); // mapping connectionId -> BankConnectionDetails
    _loadConnectorsDetails(); // mapping connectorUuid -> ConnectorDetails
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchBalance(),
      _fetchInitialTransactions(),
      _fetchAccountsAndConnections(),
    ]);
  }

  Future<void> _fetchAccountsAndConnections() async {
    try {
      final powensService = context.read<PowensService>();
      final accounts = await powensService.getAccounts();
      _accountsById.clear();
      for (final acc in accounts) {
        _accountsById[acc.id] = acc;
      }
      debugPrint('[FETCH ACCOUNTS] _accountsById contenu :');
      _accountsById.forEach((k, v) {
        debugPrint('  key: ' +
            k.toString() +
            ' (' +
            k.runtimeType.toString() +
            '), value: ' +
            (v == null ? 'null' : v.toString()));
      });
      // Get all unique connectionIds from accounts
      final connectionIds =
          accounts.map((a) => a.connectionId).toSet().toList();
      _bankCount = connectionIds.length;
      // On ne fait plus de getConnectionDetails ici, car on utilise le cache persistant
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur lors du chargement des comptes ou banques: $e');
    }
  }

  Future<void> _fetchBalance() async {
    if (!mounted) return;
    setState(() {
      _isBalanceLoading = true;
    });

    try {
      final accounts = await context.read<PowensService>().getAccounts();
      if (!mounted) return;

      final total = accounts.fold(0.0, (sum, item) => sum + item.balance);
      setState(() {
        _totalBalance = total;
        _isBalanceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBalanceLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMore) {
      _loadMoreTransactions();
    }
  }

  Future<void> _fetchInitialTransactions() async {
    setState(() {
      _isLoading = true;
      _transactions.clear();
      _groupedTransactions.clear();
      _hasMore = true;
      _error = null;
    });

    try {
      final powensService = context.read<PowensService>();
      final transactionPage = await powensService.getTransactions();

      if (mounted) {
        setState(() {
          _transactions.addAll(transactionPage.transactions);
          _groupTransactions();
          _nextPageUrl = transactionPage.nextUrl;
          _hasMore = _nextPageUrl != null;
          _isLoading = false;
        });
        // Ajout : chargement des scores carbone batch
        await _loadCarbonScoresForTransactions(transactionPage.transactions);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement des transactions: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    final powensService = context.read<PowensService>();
    try {
      final page = await powensService.getTransactions(url: _nextPageUrl);
      if (mounted) {
        setState(() {
          _transactions.addAll(page.transactions);
          _groupTransactions();
          _nextPageUrl = page.nextUrl;
          _hasMore = _nextPageUrl != null;
          _isFetchingMore = false;
        });
        // Ajout : chargement des scores carbone batch pour les nouvelles transactions
        await _loadCarbonScoresForTransactions(page.transactions);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  void _groupTransactions() {
    _groupedTransactions.clear();
    for (final tx in _transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (_groupedTransactions[dateKey] == null) {
        _groupedTransactions[dateKey] = [];
      }
      _groupedTransactions[dateKey]!.add(tx);
    }
  }

  Future<void> _loadConnectionsDetails() async {
    final powensService = context.read<PowensService>();
    final map = await powensService.loadAllConnectionDetails();
    setState(() {
      _connectionsById.clear();
      _connectionsById.addAll(map);
    });
  }

  Future<void> _loadConnectorsDetails() async {
    // Log d’investigation pour la population du mapping des connecteurs
    //debugPrint('[CONNECTORS] Début du chargement des connecteurs Powens...');
    final powensService = context.read<PowensService>();
    final map = await powensService.loadAllConnectorDetails();
    setState(() {
      _connectorsByUuid.clear();
      _connectorsByUuid.addAll(map);
      // debugPrint('[CONNECTORS] Mapping _connectorsByUuid après chargement :');
      _connectorsByUuid.forEach((k, v) {
        // debugPrint('  uuid: ' + k.toString() + ' → ' + (v == null ? 'null' : v.name.toString()));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Expense & Carbon score',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: context.onSurfaceVariantColor,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildBalanceDisplay(),
          ),
        ),
      ),
      body: _isLoading && _transactions.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!, textAlign: TextAlign.center),
                ))
              : RefreshIndicator(
                  onRefresh: _fetchInitialData,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _groupedTransactions.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _groupedTransactions.length && _hasMore) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        );
                      }

                      final date = _groupedTransactions.keys.elementAt(index);
                      final transactionsForDate = _groupedTransactions[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 16, bottom: 36.0),
                            child: Text(
                              _formatDateHeader(date),
                              style: context.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.onSurfaceColor,
                              ),
                            ),
                          ),
                          ...transactionsForDate
                              .map((tx) => _buildExpenseCard(context, tx))
                              .toList(),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildBalanceDisplay() {
    if (_isBalanceLoading) {
      return const SizedBox(
          height: 53); // Affiche un espace vide pendant le chargement
    }

    if (_totalBalance == null) {
      return const Text('Solde indisponible');
    }

    final formattedBalance = NumberFormat.currency(locale: 'fr_FR', symbol: '€')
        .format(_totalBalance);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Solde total',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey,
              ),
        ),
        Text(
          formattedBalance,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ) ??
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    }
  }

  String _formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return "Aujourd'hui";
    } else if (transactionDate == yesterday) {
      return 'Hier';
    } else {
      final formatter = DateFormat('d MMMM y', 'fr_FR');
      return formatter.format(date);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) {
      return '';
    }
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Widget _buildExpenseCard(
      BuildContext context, TransactionDetails transaction) {
    // Bank badge logic
    String? bankName;
    String? debugAccountId = transaction.accountId;
    AccountDetails? debugAccount;
    String? debugConnectionId;
    BankConnectionDetails? debugConnection;
    String? debugConnectorUuid;
    ConnectorDetails? debugConnector;
    if (_accountsById.isNotEmpty &&
        _connectionsById.isNotEmpty &&
        _bankCount > 1) {
      debugAccount = _accountsById[transaction.accountId];
      if (debugAccount != null) {
        debugConnectionId = debugAccount.connectionId;
        debugConnection = _connectionsById[debugConnectionId];
        debugConnectorUuid = debugConnection?.connectorUuid;
        debugConnector = debugConnectorUuid != null
            ? _connectorsByUuid[debugConnectorUuid]
            : null;
        if (debugConnector != null && (debugConnector.name).isNotEmpty) {
          bankName = debugConnector.name;
        }
      }
    }
    // Ajout de logs détaillés
    /* debugPrint('[POPIN EXPENSE] accountId: \\${debugAccountId}');
    debugPrint('[POPIN EXPENSE] account: \\${debugAccount?.toString()}');
    debugPrint('[POPIN EXPENSE] connectionId: \\${debugConnectionId}');
    debugPrint('[POPIN EXPENSE] connection: \\${debugConnection?.toString()}');
    debugPrint('[POPIN EXPENSE] connectorUuid: \\${debugConnectorUuid}');
    debugPrint('[POPIN EXPENSE] connector: \\${debugConnector?.toString()}');
    debugPrint('[POPIN EXPENSE] bankName: \\${bankName}');*/
    final carbonScore = _carbonScores[transaction.id];
    // debugPrint('[ExpensesScreen] Affichage score carbone pour tx \\${transaction.id} : $carbonScore');
    final formattedAmount = transaction.amount.abs().toStringAsFixed(2);
    final amountString =
        transaction.amount < 0 ? '-€$formattedAmount' : '€$formattedAmount';
    final carbonColor = AppTheme.getCarbonScoreColor(carbonScore);

    // Ajout de logs pour debug Powens (voir https://docs.powens.com/api-reference/products/data-aggregation/bank-accounts#bankaccountslist-object)
    // debugPrint('[POPIN EXPENSE] _accountsById keys: ' + _accountsById.keys.map((k) => '$k (${k.runtimeType})').join(', '));
    //debugPrint('[POPIN EXPENSE] transaction.accountId: \\${transaction.accountId} (type: \\${transaction.accountId.runtimeType})');
    // Fin logs

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (modalContext) {
            return Padding(
              padding: MediaQuery.of(modalContext).viewInsets,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nom de la banque centré
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          bankName ?? 'Banque inconnue',
                          style: modalContext.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        4.h,
                        Text(
                          _formatTransactionDate(transaction.date),
                          style: modalContext.bodyMedium.copyWith(
                            color: AppColors.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    // Montant de la transaction
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        amountString,
                        style: modalContext.titleLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Description de la transaction
                    Text(
                      _capitalize(transaction.wording),
                      style: modalContext.bodyLarge?.copyWith(
                        color: AppColors.grey700,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Ligne des badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge Catégorie
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: modalContext.badgeBorderRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                transaction.categoryLabel?.isNotEmpty == true
                                    ? _capitalize(transaction.categoryLabel!)
                                    : (transaction.category?.isNotEmpty == true
                                        ? _capitalize(transaction.category!)
                                        : 'Autre'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.label_outline,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Badge Score Carbone
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: carbonColor.withOpacity(0.15),
                            borderRadius: modalContext.badgeBorderRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                carbonScore != null
                                    ? carbonScore.toStringAsFixed(2) + ' kgCO₂e'
                                    : '??',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: carbonColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.eco,
                                size: 16,
                                color: carbonColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Encart pour les notes
                    GestureDetector(
                      onTap: () {
                        // TODO: Implémenter l'ouverture de l'éditeur de notes
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit_note,
                                color: AppColors.grey600, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ajouter une note ou des détails...',
                                style: modalContext.bodyMedium?.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Champ Catégorie cliquable
                    GestureDetector(
                      onTap: () {
                        // TODO: Implémenter le sélecteur de catégorie
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Catégorie',
                              style: modalContext.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // Afficher la catégorie actuelle ou "Non catégorisé"
                            Text(
                              transaction.categoryLabel?.isNotEmpty == true
                                  ? _capitalize(transaction.categoryLabel!)
                                  : (transaction.category?.isNotEmpty == true
                                      ? _capitalize(transaction.category!)
                                      : 'Non catégorisé'),
                              style: modalContext.bodyMedium?.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.grey500,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bouton "Améliorer ma dépense"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implémenter la logique d'amélioration
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Améliorer ma dépense',
                          style: modalContext.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: context.badgeBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(width: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _capitalize(transaction.wording),
                            style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ) ??
                                const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          amountString,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ) ??
                                  const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Les badges Catégorie et Score sont maintenant dans une Row
                    Row(
                      children: [
                        // if (bankBadge != null) bankBadge,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: context.badgeBorderRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                transaction.categoryLabel?.isNotEmpty == true
                                    ? _capitalize(transaction.categoryLabel!)
                                    : (transaction.category?.isNotEmpty == true
                                        ? _capitalize(transaction.category!)
                                        : 'Autre'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.label_outline,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: carbonColor.withOpacity(0.15),
                            borderRadius: context.badgeBorderRadius,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                carbonScore != null
                                    ? carbonScore.toStringAsFixed(2) + ' kgCO₂e'
                                    : '??',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: carbonColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.eco,
                                size: 16,
                                color: carbonColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Le prix et la flèche sont maintenant sur la même ligne et centrés
              Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.onSurfaceVariantColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
