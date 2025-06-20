import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/powens_service.dart';
import '../services/carbon_score_cache_service.dart';
import '../services/rss_cache_service.dart';
import '../theme/app_theme.dart';
import 'bank_connections_screen.dart';
import '../services/location_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  bool _locationEnabled = false;
  String? _locationAddress;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final powensService = Provider.of<PowensService>(context, listen: false);
      await powensService.refreshAllConnectionDetails();
      // Chargement de l'état de la localisation
      final enabled = await LocationService.isLocationEnabled();
      String? address;
      if (enabled) {
        address = await LocationService.getLastAddress();
      }
      if (mounted) {
        setState(() {
          _locationEnabled = enabled;
          _locationAddress = address;
        });
      }
    });
  }

  void _loadUserInfo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      setState(() {
        _user = authService.getUserInfo();
      });
    });
  }

/*
  // Méthode pour naviguer vers l'écran de connexion bancaire (actuellement non utilisée directement par la carte principale)
  Future<void> _navigateToBankConnection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankConnectionScreen()),
    );

    // Rafraîchir les données si nécessaire après le retour de l'écran de connexion
    if (result == true) {
      // Exemple: Recharger les données des comptes bancaires si nécessaire
      // _loadBankAccounts(); 
    }
  }
*/

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

  @override
  Widget build(BuildContext context) {
    final powensService = Provider.of<PowensService>(context,
        listen: false); // Obtenir PowensService

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Paramètres',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Account'),
            _buildSettingsCard(
              icon: Icons.person_outline,
              title: _user?.displayName ?? 'Profile',
              subtitle: 'Manage your personal information',
              extraText: _user?.email,
              onTap: () {},
            ),
            _buildSettingsCard(
              icon: Icons.account_balance,
              title: 'Comptes bancaires',
              subtitle: 'Connectez une nouvelle banque ou gérez vos connexions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const BankConnectionsScreenWrapper()),
                );
              },
              trailing: Consumer<PowensService>(
                  builder: (context, powensServiceInstance, child) {
                bool isConnected =
                    powensServiceInstance.connectionIds.isNotEmpty;
                String badgeText;
                Color badgeTextColor;
                Color badgeBackgroundColor;

                if (isConnected) {
                  badgeText = 'Connecté';
                  (badgeTextColor, badgeBackgroundColor) = context.successBadge;
                } else {
                  badgeText = 'Non connecté';
                  (badgeTextColor, badgeBackgroundColor) = context.errorBadge;
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBackgroundColor,
                    borderRadius: context.badgeBorderRadius,
                  ),
                  child: Text(
                    badgeText,
                    style: context.badge.copyWith(color: badgeTextColor),
                  ),
                );
              }),
            ),
            _buildSettingsCard(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Disconnect your account',
              onTap: () {
                context.read<AuthService>().signOut();
              },
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Preferences'),
            _buildSettingsCard(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: _locationEnabled && _locationAddress != null
                  ? _locationAddress!
                  : 'Set your address for local recommendations',
              onTap: () async {
                if (_locationEnabled) {
                  await LocationService.disableLocation();
                  if (mounted) {
                    setState(() {
                      _locationEnabled = false;
                      _locationAddress = null;
                    });
                  }
                } else {
                  final address = await LocationService.enableLocation();
                  if (address != null && mounted) {
                    setState(() {
                      _locationEnabled = true;
                      _locationAddress = address;
                    });
                  }
                }
              },
              trailing: Builder(
                builder: (context) {
                  String badgeText = _locationEnabled ? 'Actif' : 'Désactivé';
                  Color badgeTextColor;
                  Color badgeBackgroundColor;
                  if (_locationEnabled) {
                    (badgeTextColor, badgeBackgroundColor) =
                        context.successBadge;
                  } else {
                    badgeTextColor = context.grey700;
                    badgeBackgroundColor = context.grey200;
                  }
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBackgroundColor,
                      borderRadius: context.badgeBorderRadius,
                    ),
                    child: Text(
                      badgeText,
                      style: context.badge.copyWith(color: badgeTextColor),
                    ),
                  );
                },
              ),
            ),
            _buildSettingsCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () {},
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('About'),
            _buildSettingsCard(
              icon: Icons.info_outline,
              title: 'About Leaff',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),
            _buildSettingsCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Learn how we protect your data',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            // BOUTON DEBUG : Purge tous les caches applicatifs
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Purger tous les caches (debug)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: () async {
                  await _clearAllAppCaches();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Caches applicatifs purgés.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? extraText,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: context.bodyMedium.copyWith(
                color: context.onSurfaceVariantColor,
              ),
            ),
            if (extraText != null) ...[
              const SizedBox(height: 4),
              Text(
                extraText,
                style: context.bodyMedium.copyWith(
                  color: context.grey500,
                  fontSize: 12,
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
}
