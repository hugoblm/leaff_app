import 'package:flutter/material.dart';
import 'package:leaff_app/screens/discovery_screen.dart';
import 'package:leaff_app/screens/eco_news_screen.dart';
import 'package:leaff_app/screens/eco_tips_screen.dart';
import 'package:flutter/scheduler.dart';
import 'package:leaff_app/theme/app_theme.dart';

// --- INDICATEUR CUSTOM POUR TABBAR ---
class TabTextWidthIndicator extends Decoration {
  final Color color;
  final List<String> tabTexts;
  final TabController controller;
  final TextStyle? textStyle;
  final double indicatorHeight;
  final double indicatorRadius;

  const TabTextWidthIndicator({
    required this.color,
    required this.tabTexts,
    required this.controller,
    this.textStyle,
    this.indicatorHeight = 8,
    this.indicatorRadius = 2,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return TabTextWidthPainter(this, controller, tabTexts, textStyle, color, indicatorHeight, indicatorRadius);
  }
}

class TabTextWidthPainter extends BoxPainter {
  final TabTextWidthIndicator decoration;
  final TabController controller;
  final List<String> tabTexts;
  final TextStyle? textStyle;
  final Color color;
  final double indicatorHeight;
  final double indicatorRadius;

  TabTextWidthPainter(this.decoration, this.controller, this.tabTexts, this.textStyle, this.color, this.indicatorHeight, this.indicatorRadius);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Animation<double> animation = controller.animation!;
    final double t = animation.value - animation.value.floor();
    int fromIndex = controller.index;
    int toIndex = controller.index;
    if (animation.value > controller.index) {
      toIndex = controller.index + 1;
    } else if (animation.value < controller.index) {
      toIndex = controller.index - 1;
    }

    // Indicateur prend toute la largeur de la box de l'onglet actif
    final double tabBarWidth = configuration.size!.width;
    final double tabWidth = tabBarWidth / tabTexts.length;
    final double left = offset.dx + tabWidth * animation.value;
    final double top = offset.dy + configuration.size!.height - indicatorHeight;
    final Rect rect = Rect.fromLTWH(left, top, tabWidth, indicatorHeight);
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(indicatorRadius));
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }
}
// --- FIN INDICATEUR CUSTOM ---


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<int, ScrollController?> _tabScrollControllers = {0: null, 1: null, 2: null};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollControllers.values.forEach((controller) => controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000), 
                blurRadius: 16,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: AnimatedTabBar(
              controller: _tabController,
              tabScrollControllers: _tabScrollControllers,
            ),
            centerTitle: true,
            toolbarHeight: 64,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DiscoveryScreen(scrollControllerCallback: (controller) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _tabScrollControllers[0] = controller);
            });
          }),
          EcoNewsScreen(scrollControllerCallback: (controller) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _tabScrollControllers[1] = controller);
            });
          }),
          EcoTipsScreen(scrollControllerCallback: (controller) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _tabScrollControllers[2] = controller);
            });
          }),
        ],
      ),
    );
  }
}

class AnimatedTabBar extends StatefulWidget {
  final TabController controller;
  final Map<int, ScrollController?> tabScrollControllers;
  const AnimatedTabBar({required this.controller, required this.tabScrollControllers});

  @override
  State<AnimatedTabBar> createState() => AnimatedTabBarState();
}

class AnimatedTabBarState extends State<AnimatedTabBar> {
  final Map<int, double> iconOpacities = {0: 1.0, 1: 1.0, 2: 1.0};

  @override
  void didUpdateWidget(covariant AnimatedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (int i = 0; i < 3; i++) {
      if (widget.tabScrollControllers[i] != oldWidget.tabScrollControllers[i]) {
        oldWidget.tabScrollControllers[i]?.removeListener(() => _onTabScroll(i));
        widget.tabScrollControllers[i]?.addListener(() => _onTabScroll(i));
        _onTabScroll(i);
      }
    }
  }

  void _onTabScroll(int tabIndex) {
    final controller = widget.tabScrollControllers[tabIndex];
    final offset = controller?.offset ?? 0.0;
    final newOpacity = offset <= 0.0 ? 1.0 : 0.0;
    if (newOpacity != iconOpacities[tabIndex]) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            iconOpacities[tabIndex] = newOpacity;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < 3; i++) {
      widget.tabScrollControllers[i]?.removeListener(() => _onTabScroll(i));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: widget.controller,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      indicator: TabTextWidthIndicator(
        color: AppColors.primary,
        tabTexts: const ['Discovery', 'Eco News', 'Eco Tips'],
        controller: widget.controller,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      indicatorWeight: 0, // on gère l'épaisseur dans le custom indicator
      labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      tabs: [
        Tab(
          icon: AnimatedOpacity(
            opacity: iconOpacities[0]!,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.explore),
          ),
          text: 'Discovery',
        ),
        Tab(
          icon: AnimatedOpacity(
            opacity: iconOpacities[1]!,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.eco),
          ),
          text: 'Eco News',
        ),
        Tab(
          icon: AnimatedOpacity(
            opacity: iconOpacities[2]!,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.tips_and_updates),
          ),
          text: 'Eco Tips',
        ),
      ],
    );
  }
}

