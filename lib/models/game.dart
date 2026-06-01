import '../config.dart';

// Game Model
class Game {
  final int id;
  final String name;
  final String? categoryName;
  final int? leagueId;
  final int currentGames;
  final String? leagueLogo;

  Game({
    required this.id,
    required this.name,
    this.categoryName,
    this.leagueId,
    this.currentGames = 0,
    this.leagueLogo,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Extract league name, ID and logo from the populated relationship
    String? leagueName;
    int? leagueId;
    String? leagueLogo;

    // The API returns data directly without 'attributes' wrapper
    if (json['leagues'] != null && json['leagues'] is List) {
      final leagues = json['leagues'] as List;
      if (leagues.isNotEmpty) {
        final firstLeague = leagues[0];
        if (firstLeague is Map) {
          leagueName = firstLeague['Name'];
          leagueId = firstLeague['id'];
          if (firstLeague['Logo'] != null && firstLeague['Logo'] is Map) {
            final logoUrl = firstLeague['Logo']['url'];
            if (logoUrl != null) {
              leagueLogo = '$apiBaseUrl$logoUrl';
            }
          }
        }
      }
    }

    return Game(
      id: json['id'] ?? 0,
      name: json['Name'] ?? 'Unknown',
      categoryName: leagueName ?? 'Unknown League',
      leagueId: leagueId,
      currentGames: json['currentGames'] ?? 0,
      leagueLogo: leagueLogo,
    );
  }
}
