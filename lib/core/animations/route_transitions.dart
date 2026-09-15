import 'package:flutter/material.dart';

import 'animation_constants.dart';

/// Used whenever we navigate into a product's details screen, so the
/// motion feels identical whether the product was tapped from the
/// carousel or the browse grid/list.
Route<T> buildDetailsRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: AppDurations.screenTransition,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: AppCurves.screenTransition);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
