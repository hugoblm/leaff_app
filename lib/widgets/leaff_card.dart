import 'package:flutter/material.dart';

class LeaffCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const LeaffCard({
    required this.child,
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.all(8),
      color: color ?? Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              child: child,
            )
          : child,
    );
  }
} 