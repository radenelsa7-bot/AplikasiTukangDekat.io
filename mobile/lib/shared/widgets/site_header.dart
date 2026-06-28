import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class TukangDekatHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final TabBar? bottom;
  final bool centerTitle;

  const TukangDekatHeader({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      backgroundColor: AppTheme.navy,
      elevation: 0,
      surfaceTintColor: AppTheme.navy,
      title:
          title ??
          const Text(
            'TukangDekat',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
      actions: actions,
      bottom: bottom,
    );
  }
}
