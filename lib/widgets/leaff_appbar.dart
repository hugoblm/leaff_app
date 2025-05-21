import 'package:flutter/material.dart';

class LeaffAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const LeaffAppBar({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.green[700],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 