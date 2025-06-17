import 'package:flutter/material.dart';

class DiscoveryScreen extends StatefulWidget {
  final void Function(ScrollController)? scrollControllerCallback;
  const DiscoveryScreen({Key? key, this.scrollControllerCallback}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
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
                child: const Icon(Icons.explore, size: 32, color: Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                'Discovery',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'À venir : suggestions, découvertes et inspirations écologiques.',
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
