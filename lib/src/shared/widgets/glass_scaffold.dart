import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// A [Scaffold] with the leakless organic gradient background.
///
/// Every screen uses this so the translucent glass surfaces always sit over the
/// same fresh ice-blue wash (quality rule #2).
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBody = true,
    this.extendBodyBehindAppBar = true,
    this.safeArea = true,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.background(colors)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        body: safeArea ? SafeArea(bottom: false, child: body) : body,
      ),
    );
  }
}
