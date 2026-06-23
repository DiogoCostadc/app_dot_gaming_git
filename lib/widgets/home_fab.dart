import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

/// Standard square home button that returns the user to the home screen.
///
/// Used on every screen that previously relied on the "Liga" bottom-nav
/// tab. Designed to be dropped into a Stack as a `Positioned` child;
/// typically placed in the top-right corner just below the status bar.
class HomeFab extends StatelessWidget {
  const HomeFab({super.key});

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: TelaInicial()),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFF00FFFF), width: 2),
    );
    return Material(
      color: const Color(0xFF000033),
      shape: shape,
      elevation: 0,
      child: InkWell(
        customBorder: shape,
        splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.3),
        onTap: () => _goHome(context),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.home_rounded,
            color: Color(0xFF00FFFF),
            size: 24,
          ),
        ),
      ),
    );
  }
}
