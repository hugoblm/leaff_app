import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Pour les extensions de contexte

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Scanner',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: context.onSurfaceVariantColor,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_rounded,
              size: 80,
              color: context.onSurfaceVariantColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Fonctionnalité de scan à venir',
              style: context.bodyLarge.copyWith(
                color: context.onSurfaceVariantColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
