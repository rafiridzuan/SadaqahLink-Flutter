import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Widget? leading;

  const BlurredAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return AppBar(
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      leading: leading,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: isDark
                ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8)
                : primaryColor.withOpacity(0.85),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
