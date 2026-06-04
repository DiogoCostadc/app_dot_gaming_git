import '../config.dart';

// Standing Model
class Standing {
  final int id;
  final int? teamId;
  final String teamName;
  final String? teamLogoUrl;
  final int wins;
  final int losses;
  final int draws;
  final int points;
  final int winRounds;
  final int lossRounds;
  final String leagueLogoUrl;

  Standing({
    required this.id,
    this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    required this.wins,
    required this.losses,
    this.draws = 0,
    this.points = 0,
    required this.winRounds,
    required this.lossRounds,
    required this.leagueLogoUrl,
  });

  int get roundDifference => winRounds - lossRounds;

  factory Standing.fromJson(Map<String, dynamic> json) {
    // Extract team data from nested team object
    String teamName = 'Unknown Team';
    int? teamId;
    String? teamLogoUrl;
    if (json['team'] != null && json['team'] is Map) {
      final team = json['team'] as Map<String, dynamic>;
      teamName = team['Name'] ?? 'Unknown Team';
      teamId = team['id'];
      if (team['Logo'] != null && team['Logo'] is Map) {
        final logoUrl = team['Logo']['url'];
        if (logoUrl != null) {
          teamLogoUrl = resolveMediaUrl(logoUrl.toString());
        }
      }
    }

    // Extract league logo from nested league object
    String leagueLogoUrl = '';
    if (json['league'] != null && json['league'] is Map) {
      final league = json['league'] as Map<String, dynamic>;
      if (league['Logo'] != null && league['Logo'] is Map) {
        final logoUrl = league['Logo']['url'];
        if (logoUrl != null) {
          leagueLogoUrl = resolveMediaUrl(logoUrl.toString());
        }
      }
    }

    return Standing(
      id: json['id'] ?? 0,
      teamId: teamId,
      teamName: teamName,
      teamLogoUrl: teamLogoUrl,
      wins: json['Win'] ?? 0,
      losses: json['Losses'] ?? 0,
      draws: json['draws'] ?? json['Draws'] ?? 0,
      points: json['points'] ?? json['Points'] ?? 0,
      winRounds: json['RondasGanhas'] ?? json['WinRounds'] ?? 0,
      lossRounds: json['RondasPerdidas'] ?? json['LossRounds'] ?? 0,
      leagueLogoUrl: leagueLogoUrl,
    );
  }
}
