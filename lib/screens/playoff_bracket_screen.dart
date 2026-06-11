import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/playoff.dart';
import '../widgets/home_fab.dart';
import '../widgets/league_nav_tabs.dart';
import '../widgets/playoff_bracket.dart';

/// Standalone screen that displays the playoff bracket for a given
/// league + game pair. Reachable from the bottom navigation "Playoff" tab.
///
/// The bracket data (matches grouped by stage) and the [PlayoffSize] are
/// fetched here; the actual rendering is delegated to [PlayoffBracket].
class PlayoffBracketScreen extends StatefulWidget {
  final int leagueId;
  final int gameId;
  final String leagueName;
  final String gameName;

  const PlayoffBracketScreen({
    super.key,
    required this.leagueId,
    required this.gameId,
    required this.leagueName,
    required this.gameName,
  });

  @override
  State<PlayoffBracketScreen> createState() => _PlayoffBracketScreenState();
}

class _PlayoffBracketScreenState extends State<PlayoffBracketScreen> {
  late Future<_BracketData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Pull-to-refresh: bust the cache and reload the bracket.
  Future<void> _refresh() async {
    ApiService.clearCache();
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<_BracketData> _load() async {
    final results = await Future.wait([
      ApiService.fetchLeagueDetails(widget.leagueId),
      ApiService.fetchPlayoffMatches(widget.leagueId, widget.gameId),
    ]);
    final details = results[0] as ({String? status, PlayoffSize? size});
    final matches =
        results[1] as Map<PlayoffStage, List<PlayoffMatch>>;
    return _BracketData(
      size: details.size ?? PlayoffSize.teams8,
      matches: matches,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const bottomNavHeight = 55.0;

    return Material(
      color: const Color(0xFF000033),
      child: Stack(
        children: [
          // ========== PAGE CONTENT ==========
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            bottom: bottomNavHeight,
            child: Column(
              children: [
                // League name subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.leagueName,
                    style: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<_BracketData>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF00FF),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Erro ao carregar playoffs',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () =>
                                      setState(() => _future = _load()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF00FF),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final data = snapshot.data!;
                      final hasAny =
                          data.matches.values.any((list) => list.isNotEmpty);
                      if (!hasAny) {
                        return const Center(
                          child: Text(
                            'Sem partidas de playoff',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 16),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        color: const Color(0xFF00FFFF),
                        backgroundColor: const Color(0xFF000033),
                        child: PlayoffBracket(
                          size: data.size,
                          matchesByStage: data.matches,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ========== BOTTOM NAVBAR ==========
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomNavHeight,
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0x332B2626),
                border: Border(
                  top: BorderSide(color: Color(0xFFE000FF), width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: LeagueNavTabs(
                active: LeagueNavTab.playoff,
                gameName: widget.gameName,
                leagueName: widget.leagueName,
              ),
            ),
          ),

          // ========== HOME FAB ==========
          const Positioned(
            left: 16,
            bottom: bottomNavHeight + 16,
            child: HomeFab(),
          ),
        ],
      ),
    );
  }
}

class _BracketData {
  final PlayoffSize size;
  final Map<PlayoffStage, List<PlayoffMatch>> matches;
  _BracketData({required this.size, required this.matches});
}
