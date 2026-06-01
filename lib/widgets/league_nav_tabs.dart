import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/liga_screen.dart';
import '../screens/jornadas_screen.dart';

/// Identifies which of the three bottom tabs is currently active.
enum LeagueNavTab { liga, classificacao, jornadas }

/// Shared bottom-navigation bar used across the Liga and Jornadas screens.
///
/// The left ("Liga") tab always returns to the home screen. The other two
/// tabs navigate between the standings (Classificação) and Jornadas pages.
/// The [active] tab is rendered with the highlight style and no tap handler.
class LeagueNavTabs extends StatelessWidget {
  final LeagueNavTab active;
  final String gameName;
  final String leagueName;

  const LeagueNavTabs({
    super.key,
    required this.active,
    required this.gameName,
    required this.leagueName,
  });

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: TelaInicial()),
      ),
      (route) => false,
    );
  }

  void _goClassificacao(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LigaPage(
          gameName: gameName,
          leagueName: leagueName,
        ),
      ),
    );
  }

  void _goJornadas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PopScope(
          canPop: true,
          // Selection persists between Liga and Jornadas pages.
          onPopInvokedWithResult: (didPop, result) {},
          child: JornadasPage(
            gameName: gameName,
            leagueName: leagueName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _NavTab(
          label: 'Liga',
          fontSize: 20,
          isActive: active == LeagueNavTab.liga,
          onTap: active == LeagueNavTab.liga ? null : () => _goHome(context),
        ),
        _NavTab(
          label: 'Classificação',
          fontSize: 15,
          isActive: active == LeagueNavTab.classificacao,
          onTap: active == LeagueNavTab.classificacao
              ? null
              : () => _goClassificacao(context),
        ),
        _NavTab(
          label: 'Jornadas',
          fontSize: 15,
          isActive: active == LeagueNavTab.jornadas,
          onTap: active == LeagueNavTab.jornadas
              ? null
              : () => _goJornadas(context),
        ),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  final String label;
  final double fontSize;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavTab({
    required this.label,
    required this.fontSize,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.black.withValues(alpha: 0.7)
            : Colors.black.withValues(alpha: 0.36),
        border: isActive
            ? const Border(
                top: BorderSide(color: Color(0xFF00FFFF), width: 3),
              )
            : null,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isActive ? const Color(0xFF00FFFF) : Colors.white,
          fontSize: fontSize,
          fontFamily: 'Inter',
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
                child: content,
              ),
      ),
    );
  }
}
