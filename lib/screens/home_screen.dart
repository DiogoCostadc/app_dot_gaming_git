import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import 'liga_screen.dart';
import '../selection_provider.dart';
import '../models/game.dart';

// Custom Game List Item Widget
class GameListItem extends StatelessWidget {
  final String gameName;
  final String leagueName;
  final String matchCount;
  final String? logoUrl;
  final VoidCallback onTap;

  const GameListItem({
    super.key,
    required this.gameName,
    required this.leagueName,
    required this.matchCount,
    required this.onTap,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
        highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
        child: Column(
          children: [
            // Neon Magenta Divider (Top/Between Items)
            Container(
              width: double.infinity,
              height: 2,
              color: const Color(0xFFFF00FF),
            ),
            // Game Item Row
            Container(
              width: double.infinity,
              height: 72,
              color: const Color(0xFF000033),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo (Leading)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: const Color(0xFF1A1A4D),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (logoUrl != null && logoUrl!.isNotEmpty)
                          ? Image.network(
                              logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.sports_esports,
                                color: Colors.white54,
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.sports_esports,
                              color: Colors.white54,
                              size: 28,
                            ),
                    ),
                  ),
                  // Game Name + Tournament Brand (Center-Left)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: 0.6,
                          child: Text(
                            gameName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          leagueName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Match Count (Trailing)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      matchCount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  late Future<List<Game>> futureGames;

  @override
  void initState() {
    super.initState();
    futureGames = fetchGames();
  }

  Future<List<Game>> fetchGames() => ApiService.fetchGames();

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF000033),
      child: Stack(
        children: [
          // ========== PAGE CONTENT ==========
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: FutureBuilder<List<Game>>(
              future: futureGames,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Error loading games',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              futureGames = fetchGames();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF00FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No games found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final games = snapshot.data!;

                // DEBUG: print what the API pulled for the main page leagues
                debugPrint('=== HOME PAGE API DATA ===');
                debugPrint('Total games fetched: ${games.length}');
                for (final game in games) {
                  debugPrint(
                    '  Game: id=${game.id}, name=${game.name}, '
                    'league=${game.categoryName}, leagueId=${game.leagueId}, '
                    'logo=${game.leagueLogo}, currentGames=${game.currentGames}',
                  );
                }
                debugPrint('==========================');

                // Group games by their parent league (leagueId fallback to name)
                final Map<String, List<Game>> grouped = {};
                final List<String> order = [];
                for (final g in games) {
                  final key = (g.leagueId?.toString()) ??
                      (g.categoryName ?? 'Unknown League');
                  if (!grouped.containsKey(key)) {
                    grouped[key] = [];
                    order.add(key);
                  }
                  grouped[key]!.add(g);
                }

                return ListView.builder(
                  itemCount: order.length + 1, // +1 for bottom divider
                  itemBuilder: (context, index) {
                    if (index == order.length) {
                      return Container(
                        width: double.infinity,
                        height: 2,
                        color: const Color(0xFFFF00FF),
                      );
                    }
                    final key = order[index];
                    final groupGames = grouped[key]!;
                    final first = groupGames.first;
                    return _LeagueGroup(
                      leagueName: first.categoryName ?? 'Unknown League',
                      logoUrl: first.leagueLogo,
                      games: groupGames,
                      onGameTap: (game) {
                        context.read<SelectionProvider>().updateSelection(
                          game.leagueId ?? 0,
                          game.id,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PopScope(
                              canPop: true,
                              onPopInvokedWithResult: (didPop, result) {
                                if (didPop) {
                                  context
                                      .read<SelectionProvider>()
                                      .clearSelection();
                                }
                              },
                              child: LigaPage(
                                gameName: game.name,
                                leagueName:
                                    game.categoryName ?? 'Unknown League',
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable league group: shows the league header (logo + name + chevron),
/// and when expanded, lists each video-game league entry inside.
class _LeagueGroup extends StatefulWidget {
  final String leagueName;
  final String? logoUrl;
  final List<Game> games;
  final void Function(Game game) onGameTap;

  const _LeagueGroup({
    required this.leagueName,
    required this.logoUrl,
    required this.games,
    required this.onGameTap,
  });

  @override
  State<_LeagueGroup> createState() => _LeagueGroupState();
}

class _LeagueGroupState extends State<_LeagueGroup>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top neon magenta divider
        Container(
          width: double.infinity,
          height: 2,
          color: const Color(0xFFFF00FF),
        ),
        // League header (tap to expand/collapse)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
            highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
            child: Container(
              width: double.infinity,
              height: 72,
              color: const Color(0xFF000033),
              child: Row(
                children: [
                  // League logo
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: const Color(0xFF1A1A4D),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: (widget.logoUrl != null &&
                              widget.logoUrl!.isNotEmpty)
                          ? Image.network(
                              widget.logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.emoji_events,
                                color: Colors.white54,
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.emoji_events,
                              color: Colors.white54,
                              size: 28,
                            ),
                    ),
                  ),
                  // League name
                  Expanded(
                    child: Text(
                      widget.leagueName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Chevron
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF00FFFF),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expanded children (game rows)
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expanded
              ? Column(
                  children: [
                    for (final game in widget.games)
                      _LeagueGroupItem(
                        game: game,
                        onTap: () => widget.onGameTap(game),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// A single video-game row inside an expanded league group.
class _LeagueGroupItem extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const _LeagueGroupItem({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
        highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A3D),
            border: Border(
              top: BorderSide(color: Color(0xFF1A1A4D), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF00FFFF),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  game.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
