import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

// Couleurs de l'application
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF366444);
  static const Color background = Color(0xFFF5F6F7);
  static const Color surface = Colors.white;
  
  // Texte
  static const Color onPrimary = Color(0xFF212529);
  static const Color onSurface = Color(0xFF212529);
  static const Color onSurfaceVariant = Color(0xFF6C757D);
  
  // Badges
  static const Color success = Color(0xFF198754);
  static const Color successBackground = Color(0x1A198754);
  
  static const Color warning = Color(0xFFFD7E14);
  static const Color warningBackground = Color(0x1AFD7E14);
  
  static const Color info = Color(0xFF0D6EFD);
  static const Color infoBackground = Color(0x1A0D6EFD);
  
  // États
  static const Color error = Color(0xFFDC3545);
  static const Color errorBackground = Color(0x1ADC3545);
  
  // Gris
  static const Color grey100 = Color(0xFFF8F9FA);
  static const Color grey200 = Color(0xFFE9ECEF);
  static const Color grey300 = Color(0xFFDEE2E6);
  static const Color grey400 = Color(0xFFCED4DA);
  static const Color grey500 = Color(0xFFADB5BD);
  static const Color grey600 = Color(0xFF6C757D);
  static const Color grey700 = Color(0xFF495057);
  static const Color grey800 = Color(0xFF343A40);
  static const Color grey900 = Color(0xFF212529);
}

// Styles de texte de l'application
class AppTextStyles {
  // Titres
  static final TextStyle headlineSmall = GoogleFonts.instrumentSans(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );
  
  static final TextStyle titleLarge = GoogleFonts.instrumentSans(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );
  
  static final TextStyle titleMedium = GoogleFonts.instrumentSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
  );
  
  // Corps de texte
  static final TextStyle bodyLarge = GoogleFonts.instrumentSans(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );
  
  static final TextStyle bodyMedium = GoogleFonts.instrumentSans(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurfaceVariant,
  );
  
  // Boutons
  static final TextStyle button = GoogleFonts.instrumentSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // Badges
  static final TextStyle badge = GoogleFonts.instrumentSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
}

// Thème principal de l'application
class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.background,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        foregroundColor: AppColors.onSurface,
        // Style du bouton de retour par défaut
        iconTheme: const IconThemeData(
          color: AppColors.onSurface, // Couleur de l'icône
          size: 24.0,
        ),
        // Style du bouton de retour personnalisé
        actionsIconTheme: const IconThemeData(
          color: AppColors.onSurface, // Couleur des icônes d'actions
          size: 24.0,
        ),
      ),
      // Style personnalisé pour les IconButton (utilisé pour le bouton de retour)
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.onSurface, // Couleur de l'icône
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surface,
        margin: const EdgeInsets.only(bottom: 10),
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: AppColors.surface,
      ),
    );
  }
  
  // Thème sombre (à compléter selon les besoins)
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      useMaterial3: true,
      // À définir selon les besoins
    );
  }
}

// Extension pour les couleurs de l'application
extension AppColorsExtension on BuildContext {
  // Méthodes d'accès aux couleurs
  Color get primaryColor => AppColors.primary;
  Color get backgroundColor => AppColors.background;
  Color get surfaceColor => AppColors.surface;
  Color get onPrimaryColor => AppColors.onPrimary;
  Color get onSurfaceColor => AppColors.onSurface;
  Color get onSurfaceVariantColor => AppColors.onSurfaceVariant;
  Color get successColor => AppColors.success;
  Color get warningColor => AppColors.warning;
  Color get infoColor => AppColors.info;
  Color get errorColor => AppColors.error;
  
  // Méthodes pour les couleurs de gris
  Color get grey100 => AppColors.grey100;
  Color get grey200 => AppColors.grey200;
  Color get grey300 => AppColors.grey300;
  Color get grey400 => AppColors.grey400;
  Color get grey500 => AppColors.grey500;
  Color get grey600 => AppColors.grey600;
  Color get grey700 => AppColors.grey700;
  Color get grey800 => AppColors.grey800;
  Color get grey900 => AppColors.grey900;
}

// Extension pour les styles de texte
extension AppTextStylesExtension on BuildContext {
  // Titres
  TextStyle get headlineSmall => AppTextStyles.headlineSmall;
  TextStyle get titleLarge => AppTextStyles.titleLarge;
  TextStyle get titleMedium => AppTextStyles.titleMedium;
  
  // Corps de texte
  TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  TextStyle get bodyMedium => AppTextStyles.bodyMedium;
  
  // Boutons
  TextStyle get button => AppTextStyles.button;
  
  // Badges
  TextStyle get badge => AppTextStyles.badge;
}

// Extension pour les espacements
extension AppSpacing on num {
  SizedBox get h => SizedBox(height: toDouble());
  SizedBox get w => SizedBox(width: toDouble());
}

// Extension pour les bordures
extension AppBorders on BuildContext {
  BorderRadius get smallBorderRadius => BorderRadius.circular(8);
  BorderRadius get mediumBorderRadius => BorderRadius.circular(12);
  BorderRadius get largeBorderRadius => BorderRadius.circular(16);
  
  BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}

// Extension pour les badges
extension BadgeStyleExtension on BuildContext {
  (Color, Color) get successBadge => (AppColors.success, AppColors.successBackground);
  (Color, Color) get warningBadge => (AppColors.warning, AppColors.warningBackground);
  (Color, Color) get infoBadge => (AppColors.info, AppColors.infoBackground);
  (Color, Color) get errorBadge => (AppColors.error, AppColors.errorBackground);
}

// Extension pour accéder facilement au thème
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
