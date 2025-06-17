import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/powens_service.dart';
import '../theme/app_theme.dart';
import 'bank_connections_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final powensService = Provider.of<PowensService>(context, listen: false);
      await powensService.refreshAllConnectionDetails();
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

  @override
  Widget build(BuildContext context) {
    final powensService = Provider.of<PowensService>(context, listen: false); // Obtenir PowensService
    
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
              onTap: () async {
                debugPrint('SettingsScreen: "Comptes bancaires" card tapped.');

                if (powensService.connectionIds.isEmpty) {
                  debugPrint('SettingsScreen: No connections found. Initiating new connection flow.');
                  
                  if (powensService.userId == null) {
                    debugPrint('SettingsScreen: Powens userId is null. Calling initializePowensUserAndGetId().');
                    final String? powensUserId = await powensService.initializePowensUserAndGetId();
                    
                    if (powensUserId == null) {
                      debugPrint('SettingsScreen: Failed to initialize Powens user.');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erreur d\'initialisation du service bancaire.')),
                        );
                      }
                      return;
                    }
                    
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.savePowensUserId(powensUserId);
                    debugPrint('SettingsScreen: Powens user initialized and saved to Firebase. UserId: $powensUserId');
                  } else {
                      debugPrint('SettingsScreen: Powens userId already exists: ${powensService.userId}. Proceeding to login.');
                  }

                  debugPrint('SettingsScreen: Calling powensService.login() to get webview URL.');
                  bool? loginInitiated = await powensService.login();
                  if (loginInitiated == true) {
                    debugPrint('SettingsScreen: Login successful, webview should be opening.');
                  } else {
                    debugPrint('SettingsScreen: powensService.login() failed.');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Impossible d\'initier la connexion bancaire. Veuillez réessayer.')),
                      );
                    }
                  }
                } else {
                  debugPrint('SettingsScreen: Connections found. Navigating to BankConnectionsScreen.');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BankConnectionsScreenWrapper()),
                  );
                }
              },
              trailing: Consumer<PowensService>(
                builder: (context, powensServiceInstance, child) {
                  bool isConnected = powensServiceInstance.connectionIds.isNotEmpty;
                  String badgeText;
                  Color badgeBackgroundColor;
                  Color badgeTextColor;

                  if (isConnected) {
                    badgeText = 'Connecté';
                    badgeBackgroundColor = Colors.green.withOpacity(0.1);
                    badgeTextColor = Colors.green;
                  } else {
                    badgeText = 'Non connecté';
                    badgeBackgroundColor = Colors.grey.shade200; // Fond gris clair
                    badgeTextColor = Colors.grey.shade700;     // Texte gris foncé
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
              ),
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
              subtitle: 'Set your address for local recommendations',
              onTap: () {},
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
        trailing: trailing ?? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: context.onSurfaceVariantColor,
        ),
      ),
    );
  }
}
