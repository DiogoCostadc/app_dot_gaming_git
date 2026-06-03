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
  final VoidCallback onTap;

  const GameListItem({
    super.key,
    required this.gameName,
    required this.leagueName,
    required this.matchCount,
    required this.onTap,
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
                        image: const DecorationImage(
                          image: NetworkImage("https://placehold.co/50x50"),
                          fit: BoxFit.cover,
                        ),
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

                return ListView.builder(
                  itemCount: games.length + 1, // +1 for bottom divider
                  itemBuilder: (context, index) {
                    if (index == games.length) {
                      // Bottom divider to close the list
                      return Container(
                        width: double.infinity,
                        height: 2,
                        color: const Color(0xFFFF00FF),
                      );
                    }
                    final game = games[index];
                    return GameListItem(
                      gameName: game.name,
                      leagueName: game.categoryName ?? 'Unknown League',
                      matchCount: game.currentGames.toString(),
                      onTap: () {
                        // Update provider with selected league and game
                        context.read<SelectionProvider>().updateSelection(
                          game.leagueId ?? 0,
                          game.id,
                        );

                        // Navigate to LigaPage with PopScope wrapper
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PopScope(
                              canPop: true,
                              onPopInvokedWithResult: (didPop, result) {
                                if (didPop) {
                                  // Clear selection when navigating back
                                  context.read<SelectionProvider>().clearSelection();
                                }
                              },
                              child: LigaPage(
                                gameName: game.name,
                                leagueName: game.categoryName ?? 'Unknown League',
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
