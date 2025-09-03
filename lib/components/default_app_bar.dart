// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:garagelink/vehicules/car%20widgets/ui_constants.dart';
import 'package:get/get.dart';

/// AppBar réutilisable pour Scaffold (PreferredSizeWidget)
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget; // si tu veux un titre personnalisé (ex: icône + colonne)
  final String? subtitle; // optionnel (sera affiché sous le title si titleWidget null)
  final bool centerTitle;
  final bool showBack;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool showDelete;
  final VoidCallback? onDelete;
  final List<Widget>? actions;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final IconThemeData? iconTheme;

  const CustomAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.centerTitle = false,
    this.showBack = true,
    this.leading,
    this.onBack,
    this.showDelete = false,
    this.onDelete,
    this.actions,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.iconTheme,
  })  : assert(title != null || titleWidget != null, 'title or titleWidget must be provided'),
        super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _defaultBack() {
    HapticFeedback.lightImpact();
    try {
      Get.back();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? primaryBlue;
    final fg = foregroundColor ?? Colors.white;

    final List<Widget> finalActions = [
      if (showDelete)
        IconButton(
          tooltip: 'Supprimer',
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (onDelete != null) onDelete!();
          },
        ),
      if (actions != null) ...actions!,
    ];

    final titleContent = titleWidget ??
        Column(
          crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        );

    return AppBar(
      iconTheme: iconTheme ?? const IconThemeData(color: Colors.white),
      elevation: elevation,
      backgroundColor: bg,
      foregroundColor: fg,
      centerTitle: centerTitle,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: onBack ?? _defaultBack,
                )
              : null),
      title: titleContent,
      actions: finalActions,
      flexibleSpace: gradient != null ? Container(decoration: BoxDecoration(gradient: gradient)) : null,
    );
  }
}

/// SliverAppBar réutilisable (pour CustomScrollView)
class SliverCustomAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final bool showBack;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool showDelete;
  final VoidCallback? onDelete;
  final List<Widget>? actions;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final IconThemeData? iconTheme;

  const SliverCustomAppBar({
    Key? key,
    this.title,
    this.titleWidget,
    this.centerTitle = false,
    this.showBack = true,
    this.leading,
    this.onBack,
    this.showDelete = false,
    this.onDelete,
    this.actions,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.expandedHeight = 160,
    this.pinned = true,
    this.floating = false,
    this.iconTheme,
  })  : assert(title != null || titleWidget != null, 'title or titleWidget must be provided'),
        super(key: key);

  void _defaultBack() {
    HapticFeedback.lightImpact();
    try {
      Get.back();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? primaryBlue;
    final fg = foregroundColor ?? Colors.white;

    final List<Widget> finalActions = [
      if (showDelete)
        IconButton(
          tooltip: 'Supprimer',
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (onDelete != null) onDelete!();
          },
        ),
      if (actions != null) ...actions!,
    ];

    return SliverAppBar(
      iconTheme: iconTheme ?? const IconThemeData(color: Colors.white),
      elevation: elevation,
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      backgroundColor: bg,
      foregroundColor: fg,
      centerTitle: centerTitle,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: onBack ?? _defaultBack,
                )
              : null),
      title: titleWidget ?? Text(title!, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      actions: finalActions,
      flexibleSpace: FlexibleSpaceBar(
        background: gradient != null
            ? Container(decoration: BoxDecoration(gradient: gradient))
            : Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bg, darkBlue]))),
      ),
    );
  }
}
