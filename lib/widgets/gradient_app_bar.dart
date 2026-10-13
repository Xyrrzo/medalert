import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GradientAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) => AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: actions,
        flexibleSpace: Container(decoration: AppConstants.gradientBox(radius: 0)),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
