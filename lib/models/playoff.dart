import 'package:flutter/foundation.dart';
import '../config.dart';

/// Stages of the playoff bracket, ordered from earliest (most teams) to final.
///
/// Stage values come from Strapi as Portuguese identifiers:
///   Oitavos_de_final → Round of 16 (8 matches)
///   Quartos_de_final → Quarterfinals (4 matches)
///   Semi_final       → Semifinals (2 matches)
///   Final            → Final (1 match)
enum PlayoffStage {
  roundOf16,
  quarterfinal,
  semifinal,
  finalStage;

  /// The Strapi enum identifier this stage corresponds to.
  String get apiValue {
    switch (this) {
      case PlayoffStage.roundOf16:
        return 'Oitavos_de_final';
      case PlayoffStage.quarterfinal:
        return 'Quartos_de_final';
      case PlayoffStage.semifinal:
        return 'Semi_final';
      case PlayoffStage.finalStage:
        return 'Final';
    }
  }

  /// Short user-facing label.
  String get label {
    switch (this) {
      case PlayoffStage.roundOf16:
        return 'Oitavos';
      case PlayoffStage.quarterfinal:
        return 'Quartos';
      case PlayoffStage.semifinal:
        return 'Semi-final';
      case PlayoffStage.finalStage:
        return 'Final';
    }
  }

  /// Number of matches in this stage.
  int get matchCount {
    switch (this) {
      case PlayoffStage.roundOf16:
        return 8;
      case PlayoffStage.quarterfinal:
        return 4;
      case PlayoffStage.semifinal:
        return 2;
      case PlayoffStage.finalStage:
        return 1;
    }
  }

  static PlayoffStage? fromApi(String? value) {
    if (value == null) return null;
    for (final s in PlayoffStage.values) {
      if (s.apiValue == value) return s;
    }
    return null;
  }
}

/// PlayoffSize on the League entry tells us how many rounds this bracket has.
enum PlayoffSize {
  teams2,
  teams4,
  teams8,
  teams16;

  String get apiValue {
    switch (this) {
      case PlayoffSize.teams2:
        return 'Teams_2';
      case PlayoffSize.teams4:
        return 'Teams_4';
      case PlayoffSize.teams8:
        return 'Teams_8';
      case PlayoffSize.teams16:
        return 'Teams_16';
    }
  }

  /// Stages included in this bracket size, in display order (earliest first).
  List<PlayoffStage> get stages {
    switch (this) {
      case PlayoffSize.teams2:
        return [PlayoffStage.finalStage];
      case PlayoffSize.teams4:
        return [PlayoffStage.semifinal, PlayoffStage.finalStage];
      case PlayoffSize.teams8:
        return [
          PlayoffStage.quarterfinal,
          PlayoffStage.semifinal,
          PlayoffStage.finalStage,
        ];
      case PlayoffSize.teams16:
        return [
          PlayoffStage.roundOf16,
          PlayoffStage.quarterfinal,
          PlayoffStage.semifinal,
          PlayoffStage.finalStage,
        ];
    }
  }

  static PlayoffSize? fromApi(String? value) {
    if (value == null) return null;
    for (final s in PlayoffSize.values) {
      if (s.apiValue == value) return s;
    }
    return null;
  }
}

/// A single match in the playoff bracket.
class PlayoffMatch {
  final int id;
  final String? documentId;
  final PlayoffStage? stage;
  /// 1-based slot index within the stage. Used to sort matches into the
  /// canonical bracket order (top → bottom). Comes from Strapi's
  /// `MatchNumber` field.
  final int? matchNumber;
  final String? matchStatus;
  final String? type;
  final int? homeScore;
  final int? awayScore;
  final String? homeTeamName;
  final String? homeTeamLogo;
  final String? awayTeamName;
  final String? awayTeamLogo;

  const PlayoffMatch({
    required this.id,
    this.documentId,
    this.stage,
    this.matchNumber,
    this.matchStatus,
    this.type,
    this.homeScore,
    this.awayScore,
    this.homeTeamName,
    this.homeTeamLogo,
    this.awayTeamName,
    this.awayTeamLogo,
  });

  factory PlayoffMatch.fromJson(Map<String, dynamic> json) {
    String? extractTeamName(dynamic raw) {
      if (raw is Map) return raw['Name']?.toString();
      return null;
    }

    String? extractTeamLogo(dynamic raw) {
      if (raw is Map && raw['Logo'] is Map) {
        final url = (raw['Logo'] as Map)['url'];
        if (url != null) return resolveMediaUrl(url);
      }
      return null;
    }

    final rawStage = json['Stage']?.toString();
    final parsedStage = PlayoffStage.fromApi(rawStage);

    final match = PlayoffMatch(
      id: json['id'] ?? 0,
      documentId: json['documentId']?.toString(),
      stage: parsedStage,
      matchNumber: json['MatchNumber'] is int
          ? json['MatchNumber'] as int
          : int.tryParse(json['MatchNumber']?.toString() ?? ''),
      matchStatus: json['MatchStatus']?.toString(),
      type: json['Type']?.toString(),
      homeScore: json['HomeScore'] is int ? json['HomeScore'] as int : null,
      awayScore: json['AwayScore'] is int ? json['AwayScore'] as int : null,
      homeTeamName: extractTeamName(json['HomeTeam']),
      homeTeamLogo: extractTeamLogo(json['HomeTeam']),
      awayTeamName: extractTeamName(json['AwayTeam']),
      awayTeamLogo: extractTeamLogo(json['AwayTeam']),
    );

    debugPrint(
      'PlayoffMatch.fromJson: id=${match.id} '
      'rawStage="$rawStage" parsed=${parsedStage?.name ?? "DROPPED"} '
      'matchNumber=${match.matchNumber} '
      'home="${match.homeTeamName}" (${match.homeScore}) vs '
      'away="${match.awayTeamName}" (${match.awayScore})',
    );

    return match;
  }
}
