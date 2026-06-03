import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

/// Floating action button that returns the user to the home screen.
///
/// Used on every screen that previously relied on the "Liga" bottom-nav
/// tab. Designed to be dropped into a Stack as a `Positioned` child; the
/// caller controls placement (typically bottom-right, just above the
/// bottom navigation bar).
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
    return Material(
      color: const Color(0xFF000033),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFF00FFFF), width: 2),
      ),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.3),
        onTap: () => _goHome(context),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.home_rounded,
            color: Color(0xFF00FFFF),
            size: 28,
          ),
        ),
      ),
    );
  }
}
