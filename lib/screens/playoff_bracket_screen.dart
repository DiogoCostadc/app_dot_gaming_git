import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/playoff.dart';
import '../widgets/playoff_bracket.dart';

/// Standalone screen that displays the playoff bracket for a given
/// league + game pair. Reachable from the Liga page via the "Playoff"
/// button next to the Classificação header.
///
/// The bracket data (matches grouped by stage) and the [PlayoffSize] are
/// fetched here; the actual rendering is delegated to [PlayoffBracket].
class PlayoffBracketScreen extends StatefulWidget {
  final int leagueId;
  final int gameId;
  final String leagueName;

  const PlayoffBracketScreen({
    super.key,
    required this.leagueId,
    required this.gameId,
    required this.leagueName,
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
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      body: Column(
        children: [
          // Top nav bar (back button + title)
          Container(
            width: double.infinity,
            height: 76 + statusBarHeight,
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 2, color: Color(0xB5FD01FA)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Playoffs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
          ),
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
          // Bracket
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
                            onPressed: () => setState(() => _future = _load()),
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
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }
                return PlayoffBracket(
                  size: data.size,
                  matchesByStage: data.matches,
                );
              },
            ),
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
