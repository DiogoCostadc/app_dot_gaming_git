import 'package:flutter/foundation.dart';
import '../config.dart';

class Match {
  final String documentId;
  final int id;
  final String streamUrl;
  final String matchStatus;
  final int homeScore;
  final int awayScore;
  final Team homeTeam;
  final Team awayTeam;
  final String leagueName;
  final String type;
  final String dateTime;

  Match({
    required this.documentId,
    required this.id,
    required this.streamUrl,
    required this.matchStatus,
    required this.homeScore,
    required this.awayScore,
    required this.homeTeam,
    required this.awayTeam,
    required this.leagueName,
    required this.type,
    required this.dateTime,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    // DEBUG: Print match data structure
    debugPrint('=== DEBUG Match.fromJson ===');
    debugPrint('Match players field: ${json['players']}');
    debugPrint('Match players type: ${json['players'].runtimeType}');
    debugPrint('Type field: ${json['Type']}');
    debugPrint('Type field type: ${json['Type'].runtimeType}');
    debugPrint('type field: ${json['type']}');
    debugPrint('type field type: ${json['type'].runtimeType}');
    
    // Extract league name from nested League relationship. Match entries use
    // capital `League`, Playoff entries use lowercase `league`.
    String leagueName = 'Unknown League';
    final leagueRel = json['League'] ?? json['league'];
    if (leagueRel is Map) {
      leagueName = leagueRel['Name'] ?? 'Unknown League';
    } else if (json['LeagueName'] != null) {
      leagueName = json['LeagueName'].toString();
    }
    
    // Extract full logo URLs at Match level with null checks and base URL
    const String baseUrl = apiBaseUrl;
    
    String homeLogoUrl = '';
    if (json['HomeTeam'] != null && json['HomeTeam']['Logo'] != null && json['HomeTeam']['Logo']['url'] != null) {
      homeLogoUrl = baseUrl + json['HomeTeam']['Logo']['url'].toString();
    }
    
    String awayLogoUrl = '';
    if (json['AwayTeam'] != null && json['AwayTeam']['Logo'] != null && json['AwayTeam']['Logo']['url'] != null) {
      awayLogoUrl = baseUrl + json['AwayTeam']['Logo']['url'].toString();
    }
    
    debugPrint('Home logo URL: $homeLogoUrl');
    debugPrint('Away logo URL: $awayLogoUrl');
    
    // Determine the match's game id so we can show only the players that
    // belong to this specific game (a team may have rosters for several games).
    int? matchGameId;
    final gameField = json['game'];
    if (gameField is Map && gameField['id'] != null) {
      matchGameId = gameField['id'] as int?;
    }
    debugPrint('Match game id: $matchGameId');

    // Parse teams
    final homeTeamJson = json['HomeTeam'] is Map ? Map<String, dynamic>.from(json['HomeTeam']) : <String, dynamic>{};
    final awayTeamJson = json['AwayTeam'] is Map ? Map<String, dynamic>.from(json['AwayTeam']) : <String, dynamic>{};

    homeTeamJson['Logo'] = homeLogoUrl;
    awayTeamJson['Logo'] = awayLogoUrl;

    final homeTeam = Team.fromJson(homeTeamJson, gameId: matchGameId);
    final awayTeam = Team.fromJson(awayTeamJson, gameId: matchGameId);
    
    // Players are already parsed by Team.fromJson from each team's 'players' field
    debugPrint('Home team players: ${homeTeam.players.length}');
    debugPrint('Away team players: ${awayTeam.players.length}');
    
    return Match(
      documentId: json['documentId'] ?? '',
      id: json['id'] ?? 0,
      streamUrl: json['streamurl'] ?? '',
      matchStatus: json['Matchstatus'] ?? json['MatchStatus'] ?? 'Upcoming',
      homeScore: json['HomeScore'] ?? 0,
      awayScore: json['AwayScore'] ?? 0,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      leagueName: leagueName,
      type: (json['Type'] ?? json['type'] ?? 'Unknown').toString(),
      dateTime: json['DateTime'] ?? json['dateTime'] ?? '',
    );
  }
}

class Team {
  final int id;
  final String name;
  final String logo;
  final List<Player> players;

  Team({
    required this.id,
    required this.name,
    required this.logo,
    required this.players,
  });

  factory Team.fromJson(Map<String, dynamic> json, {int? gameId}) {
    // DEBUG: Print team data
    debugPrint('=== DEBUG Team.fromJson ===');
    debugPrint('Team JSON keys: ${json.keys.toList()}');
    debugPrint('Players field: ${json['players']}');
    debugPrint('Players field type: ${json['players'].runtimeType}');

    List<Player> playersList = [];
    if (json['players'] != null && json['players'] is List) {
      var rawPlayers = (json['players'] as List).cast<dynamic>();
      debugPrint('Players list found with ${rawPlayers.length} items');

      // If we know the match's game id, keep only players whose game (single
      // relation) or games (multi relation) match it. Players without any
      // game info are kept (the server may have already filtered them).
      if (gameId != null) {
        rawPlayers = rawPlayers.where((p) {
          if (p is! Map) return false;
          final single = p['game'];
          if (single is Map && single['id'] != null) {
            return single['id'] == gameId;
          }
          final multi = p['games'];
          if (multi is List) {
            return multi.any((g) => g is Map && g['id'] == gameId);
          }
          // No game info on the player → keep it (no way to filter).
          return true;
        }).toList();
        debugPrint('Players after game filter ($gameId): ${rawPlayers.length}');
      }

      playersList = rawPlayers
          .map((player) => Player.fromJson(player as Map<String, dynamic>))
          .toList();
      debugPrint('Parsed players: ${playersList.map((p) => p.name).toList()}');
    } else {
      debugPrint('No players array found or not a list');
    }
    
    // Logo is pre-extracted at Match level as a string URL
    final logoUrl = json['Logo'] is String ? json['Logo'].toString() : '';
    
    final team = Team(
      id: json['id'] ?? 0,
      name: json['Name'] ?? 'Unknown Team',
      logo: logoUrl,
      players: playersList,
    );
    
    debugPrint('Team created: ${team.name} with ${team.players.length} players');
    debugPrint('=== END DEBUG Team.fromJson ===');
    
    return team;
  }
}

class Player {
  final int id;
  final String name;
  final String? role;
  final String? gameName;

  Player({
    required this.id,
    required this.name,
    this.role,
    this.gameName,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    debugPrint('=== DEBUG Player.fromJson ===');
    debugPrint('Player JSON: $json');
    debugPrint('Player keys: ${json.keys.toList()}');

    // The player may be linked to a game via either a single 'game' relation
    // or a multi 'games' relation. Capture whichever is present so the UI can
    // group players by game.
    String? gameName;
    final single = json['game'];
    if (single is Map && single['Name'] != null) {
      gameName = single['Name'].toString();
    } else {
      final multi = json['games'];
      if (multi is List && multi.isNotEmpty) {
        final first = multi.first;
        if (first is Map && first['Name'] != null) {
          gameName = first['Name'].toString();
        }
      }
    }

    return Player(
      id: json['id'] ?? 0,
      name: json['Nickname'] ?? json['FullName'] ?? 'Unknown Player',
      role: json['Role'],
      gameName: gameName,
    );
  }
}
