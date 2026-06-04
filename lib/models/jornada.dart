import '../config.dart';

// ========== MODELS ==========
// NOTE: This `Match` is the lightweight match model used by the Jornadas list view.
// It is distinct from the detailed `Match` in `models/match.dart` used by MatchDetailScreen.
// Both files are not imported together to avoid name conflicts.
class Match {
  final String documentId;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogoUrl;
  final String? awayTeamLogoUrl;
  final DateTime? startDateTime;
  final String? format;
  final String? status;
  final int? homeScore;
  final int? awayScore;

  Match({
    required this.documentId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogoUrl,
    this.awayTeamLogoUrl,
    this.startDateTime,
    this.format,
    this.status,
    this.homeScore,
    this.awayScore,
  });

  /// Returns the start time formatted as HH:mm in the device's local timezone
  String? get formattedTime {
    if (startDateTime == null) return null;
    final local = startDateTime!.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    String homeTeamName = 'Unknown';
    String awayTeamName = 'Unknown';
    String? homeTeamLogoUrl;
    String? awayTeamLogoUrl;

    // Extract home team
    if (json['HomeTeam'] != null && json['HomeTeam'] is Map) {
      final homeTeam = json['HomeTeam'] as Map<String, dynamic>;
      homeTeamName = homeTeam['Name'] ?? 'Unknown';

      // Handle Logo with null check
      if (homeTeam['Logo'] != null && homeTeam['Logo'] is Map) {
        final logo = homeTeam['Logo'] as Map<String, dynamic>;
        final logoUrl = logo['url'] ?? logo['formats']?['thumbnail']?['url'];
        if (logoUrl != null) {
          homeTeamLogoUrl = resolveMediaUrl(logoUrl);
        }
      }
    }

    // Extract away team
    if (json['AwayTeam'] != null && json['AwayTeam'] is Map) {
      final awayTeam = json['AwayTeam'] as Map<String, dynamic>;
      awayTeamName = awayTeam['Name'] ?? 'Unknown';

      // Handle Logo with null check
      if (awayTeam['Logo'] != null && awayTeam['Logo'] is Map) {
        final logo = awayTeam['Logo'] as Map<String, dynamic>;
        final logoUrl = logo['url'] ?? logo['formats']?['thumbnail']?['url'];
        if (logoUrl != null) {
          awayTeamLogoUrl = resolveMediaUrl(logoUrl);
        }
      }
    }

    // Parse ISO 8601 DateTime into DateTime (UTC -> local via getter)
    DateTime? startDateTime;
    final startDateStr = json['DateTime'] as String?;
    if (startDateStr != null) {
      try {
        startDateTime = DateTime.parse(startDateStr);
      } catch (_) {
        startDateTime = null;
      }
    }

    return Match(
      documentId: json['documentId'] ?? '',
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeTeamLogoUrl: homeTeamLogoUrl,
      awayTeamLogoUrl: awayTeamLogoUrl,
      startDateTime: startDateTime,
      format: json['Type'] as String? ?? 'Bo3',
      status: json['Matchstatus'] as String?,
      homeScore: json['HomeScore'] as int?,
      awayScore: json['AwayScore'] as int?,
    );
  }
}

class Jornada {
  final int id;
  final String name;
  final String? startDate;
  final List<Match> matches;
  final String? leagueLogoUrl;

  Jornada({
    required this.id,
    required this.name,
    this.startDate,
    required this.matches,
    this.leagueLogoUrl,
  });

  factory Jornada.fromJson(Map<String, dynamic> json) {
    List<Match> matches = [];

    if (json['matches'] != null && json['matches'] is List) {
      matches = (json['matches'] as List)
          .map((match) => Match.fromJson(match as Map<String, dynamic>))
          .toList();
    }

    // Extract league logo URL
    String? leagueLogoUrl;
    if (json['league'] != null && json['league'] is Map) {
      final league = json['league'] as Map<String, dynamic>;
      if (league['Logo'] != null && league['Logo'] is Map) {
        final logoUrl = league['Logo']['url'];
        if (logoUrl != null) {
          leagueLogoUrl = resolveMediaUrl(logoUrl);
        }
      }
    }

    return Jornada(
      id: json['id'] ?? 0,
      name: json['Name'] ?? 'Jornada',
      startDate: json['StartDate'] as String?,
      matches: matches,
      leagueLogoUrl: leagueLogoUrl,
    );
  }
}
