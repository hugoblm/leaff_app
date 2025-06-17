import 'package:flutter/material.dart';

class EcoTipsScreen extends StatefulWidget {
  final void Function(ScrollController)? scrollControllerCallback;
  const EcoTipsScreen({Key? key, this.scrollControllerCallback}) : super(key: key);

  @override
  State<EcoTipsScreen> createState() => _EcoTipsScreenState();
}

class _EcoTipsScreenState extends State<EcoTipsScreen> {
  late final ScrollController _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      widget.scrollControllerCallback?.call(_scrollController);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tips_and_updates, size: 32, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                'Eco Tips',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Astuces, conseils et bonnes pratiques pour un mode de vie durable.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 600), // pour permettre le scroll
      ],
    );
  }
}
