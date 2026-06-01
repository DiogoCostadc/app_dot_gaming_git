import 'package:flutter/material.dart';
import '../models/match.dart';

class PlayerList extends StatelessWidget {
  final Match match;

  const PlayerList({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    // DEBUG: Print player data
    debugPrint('=== DEBUG PlayerList.build ===');
    debugPrint('Home Team Name: ${match.homeTeam.name}');
    debugPrint('Home Team Players Count: ${match.homeTeam.players.length}');
    debugPrint('Away Team Name: ${match.awayTeam.name}');
    debugPrint('Away Team Players Count: ${match.awayTeam.players.length}');
    debugPrint('=== END DEBUG PlayerList ===');
    
    return Container(
      color: const Color(0xFF000033),
      child: Row(
        children: [
          // Home Team Players
          Expanded(
            child: match.homeTeam.players.isEmpty
              ? const Center(
                  child: Text(
                    'No players',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: match.homeTeam.players.length,
                  itemBuilder: (context, index) {
                    final player = match.homeTeam.players[index];
                    return Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: index < match.homeTeam.players.length - 1
                                ? const Color(0x33FFFFFF)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
          // Divider
          Container(
            width: 1,
            color: const Color(0xFFFF00FF),
          ),
          // Away Team Players
          Expanded(
            child: match.awayTeam.players.isEmpty
              ? const Center(
                  child: Text(
                    'No players',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: match.awayTeam.players.length,
                  itemBuilder: (context, index) {
                    final player = match.awayTeam.players[index];
                    return Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: index < match.awayTeam.players.length - 1
                                ? const Color(0x33FFFFFF)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
