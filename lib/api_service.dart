import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
import 'models/game.dart';
import 'models/jornada.dart';
import 'models/playoff.dart';
import 'models/standing.dart';

/// Simple in-memory HTTP GET cache with TTL.
///
/// Entries are keyed by absolute URL. When a cached entry is within its TTL,
/// it is returned instead of making a network request.
class _CacheEntry {
  final dynamic value;
  final DateTime expires;
  const _CacheEntry(this.value, this.expires);
}

class ApiService {
  static const String baseUrl = '$apiBaseUrl/api';

  /// Default cache TTL — most responses can be served from cache for this long.
  static const Duration _defaultTtl = Duration(minutes: 5);

  /// In-memory cache keyed by URL.
  static final Map<String, _CacheEntry> _cache = {};

  /// Clear the entire cache (e.g. after a write/mutation) or a specific URL.
  static void clearCache([String? urlPrefix]) {
    if (urlPrefix == null) {
      _cache.clear();
    } else {
      _cache.removeWhere((k, _) => k.startsWith(urlPrefix));
    }
  }

  /// Performs a GET with optional caching. If [useCache] is true and a fresh
  /// entry exists, it is returned directly. The [parse] callback converts the
  /// decoded JSON body into the return type [T].
  static Future<T> _cachedGet<T>(
    Uri uri, {
    required T Function(Map<String, dynamic>) parse,
    bool useCache = true,
    Duration? ttl,
  }) async {
    final key = uri.toString();
    final now = DateTime.now();

    if (useCache) {
      final cached = _cache[key];
      if (cached != null && now.isBefore(cached.expires)) {
        debugPrint('ApiService: cache HIT for $key');
        return cached.value as T;
      }
    }

    debugPrint('ApiService: GET $key');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      debugPrint('ApiService: GET $key failed: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      throw Exception('GET $key failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    debugPrint('ApiService: GET $key success (${response.body.length} bytes)');
    final parsed = parse(json);

    if (useCache) {
      _cache[key] = _CacheEntry(parsed, now.add(ttl ?? _defaultTtl));
    }
    return parsed;
  }

  // ========== Games ==========

  /// Fetch the list of (league, game) pairs for the home page.
  ///
  /// We query the `/leagues` collection (the League content type) and expand
  /// its `games` relation, then flatten the result so each entry represents a
  /// single game inside a single league. This ensures the home page is
  /// league-driven: a league with multiple games shows one row per game, and
  /// a game that belongs to multiple leagues shows up once under each.
  static Future<List<Game>> fetchGames() async {
    final uri = Uri.parse(
      '$baseUrl/leagues?populate[games]=true&populate[Logo]=true',
    );
    return _cachedGet<List<Game>>(
      uri,
      parse: (json) {
        final List<dynamic> leaguesData = json['data'] ?? [];
        debugPrint('ApiService.fetchGames: ${leaguesData.length} leagues returned');

        final List<Game> result = [];
        for (final l in leaguesData) {
          if (l is! Map) continue;
          final league = l as Map<String, dynamic>;
          final leagueId = league['id'] as int?;
          final leagueName = league['Name']?.toString() ?? 'Unknown League';

          String? leagueLogo;
          if (league['Logo'] is Map) {
            final logoUrl = (league['Logo'] as Map)['url'];
            if (logoUrl != null) leagueLogo = resolveMediaUrl(logoUrl.toString());
          }

          final games = league['games'];
          if (games is! List || games.isEmpty) {
            debugPrint('  League "$leagueName" (id=$leagueId) has no games');
            continue;
          }

          for (final g in games) {
            if (g is! Map) continue;
            final game = g as Map<String, dynamic>;
            result.add(Game(
              id: game['id'] ?? 0,
              name: game['Name']?.toString() ?? 'Unknown',
              categoryName: leagueName,
              leagueId: leagueId,
              currentGames: game['currentGames'] ?? 0,
              leagueLogo: leagueLogo,
            ));
          }
        }
        debugPrint('ApiService.fetchGames: flattened to ${result.length} (league, game) pairs');
        return result;
      },
    );
  }

  // ========== Standings ==========

  /// Fetch standings with dynamic leagueId and gameId.
  ///
  /// When the server-side filter returns nothing and [useFallback] is true,
  /// the entire standings collection is fetched and filtered on the client.
  /// This is expensive, so callers that already know a league may legitimately
  /// have no standings (e.g. playoff-only leagues) should pass
  /// `useFallback: false` to avoid the wasteful full download.
  static Future<List<Standing>> fetchStandings(
    int? leagueId,
    int? gameId, {
    bool useFallback = true,
  }) async {
    if (leagueId == null || gameId == null) {
      throw Exception('League ID and Game ID are required');
    }

    final uri = Uri.parse(
      '$baseUrl/standings'
      '?filters[league][id][\$eq]=$leagueId'
      '&filters[game][id][\$eq]=$gameId'
      '&populate[team][populate]=Logo'
      '&populate[league][populate]=Logo'
      '&sort=Win:desc',
    );

    final standings = await _cachedGet<List<Standing>>(
      uri,
      parse: (json) {
        final List<dynamic> data = json['data'] ?? [];
        return data.map((s) => Standing.fromJson(s)).toList();
      },
    );

    // If server-side filter returned nothing, optionally fall back to
    // client-side filtering of the whole collection.
    if (standings.isEmpty && useFallback) {
      return _fetchAllStandingsAndFilter(leagueId, gameId);
    }
    return standings;
  }

  /// Fallback: fetch all standings and filter on the client.
  static Future<List<Standing>> _fetchAllStandingsAndFilter(int leagueId, int gameId) async {
    final uri = Uri.parse(
      '$baseUrl/standings?populate[team][populate]=Logo&populate[league][populate]=Logo&sort=Win:desc',
    );

    return _cachedGet<List<Standing>>(
      uri,
      parse: (json) {
        final List<dynamic> data = json['data'] ?? [];
        final filtered = data.where((s) {
          final m = s as Map<String, dynamic>;
          final league = m['league'];
          final game = m['game'];
          final hasLeague = league is Map && league['id'] == leagueId;
          final hasGame = game is Map && game['id'] == gameId;
          return hasLeague && hasGame;
        }).toList();
        return filtered.map((s) => Standing.fromJson(s)).toList();
      },
    );
  }

  // ========== Matches ==========

  /// Fetch match details by documentId.
  static Future<Map<String, dynamic>> fetchMatchDetails(String documentId) async {
    if (documentId.isEmpty) {
      throw Exception('Document ID is required');
    }
    final uri = Uri.parse(
      '$baseUrl/matches/$documentId'
      '?populate[HomeTeam][populate][Logo]=true'
      '&populate[HomeTeam][populate][players][populate]=*'
      '&populate[AwayTeam][populate][Logo]=true'
      '&populate[AwayTeam][populate][players][populate]=*'
      '&populate[game]=true',
    );
    return _cachedGet<Map<String, dynamic>>(
      uri,
      // Match detail changes frequently during a live match; use shorter TTL.
      ttl: const Duration(seconds: 30),
      parse: (json) => (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  // ========== Jornadas ==========

  /// Fetch jornadas for the selected league/game, with matches populated.
  static Future<List<Jornada>> fetchJornadas(int? leagueId, int? gameId) async {
    if (leagueId == null || gameId == null) {
      throw Exception('League ID and Game ID are required');
    }
    final uri = Uri.parse(
      '$baseUrl/jornadas'
      '?filters[league][id][\$eq]=$leagueId'
      '&filters[game][id][\$eq]=$gameId'
      '&sort=Number:ASC'
      '&populate[matches][populate][HomeTeam][populate][0]=Logo'
      '&populate[matches][populate][AwayTeam][populate][0]=Logo'
      '&populate[league][populate][0]=Logo',
    );
    return _cachedGet<List<Jornada>>(
      uri,
      parse: (json) {
        final List<dynamic> data = json['data'] ?? [];
        return data.map((j) => Jornada.fromJson(j as Map<String, dynamic>)).toList();
      },
    );
  }

  // ========== Team players ==========

  /// Fetch players for a team. Tries a sequence of endpoint variants because
  /// Strapi v5 resource naming may differ between installations.
  static Future<List<dynamic>> fetchTeamPlayers(int teamId) async {
    const populate = '&populate=*';
    final endpoints = [
      '$baseUrl/players?filters[team][id][\$eq]=$teamId$populate',
      '$baseUrl/player?filters[team][id][\$eq]=$teamId$populate',
      '$baseUrl/players?filters[teams][id][\$eq]=$teamId$populate',
      '$baseUrl/players?filters[team][documentId][\$eq]=$teamId$populate',
    ];

    for (final url in endpoints) {
      final uri = Uri.parse(url);
      debugPrint('Fetching players from: $uri');
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = jsonDecode(response.body);
          final List<dynamic> playersData = jsonData['data'] ?? [];
          debugPrint('Found ${playersData.length} players via $url');
          if (playersData.isNotEmpty) {
            return playersData;
          }
        } else {
          debugPrint('Endpoint $url failed: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Endpoint $url threw: $e');
      }
    }

    // Fallback: try team endpoint with populate=players.
    final teamUri = Uri.parse('$baseUrl/teams/$teamId?populate=players');
    debugPrint('Fallback to team endpoint: $teamUri');
    final teamResponse = await http.get(teamUri);
    if (teamResponse.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(teamResponse.body);
      final teamData = jsonData['data'] ?? {};
      final dynamic playersData = teamData['players'];
      if (playersData is List) return playersData;
      if (playersData is Map && playersData['data'] is List) {
        return playersData['data'] as List;
      }
    } else {
      debugPrint('Team endpoint also failed: ${teamResponse.statusCode}');
    }
    return [];
  }

  // ========== Team standings / matches ==========

  /// Fetch standings for a specific team (appearances across leagues).
  static Future<List<dynamic>> fetchTeamStandings(int teamId) async {
    final uri = Uri.parse(
      '$baseUrl/standings'
      '?filters[team][id][\$eq]=$teamId'
      '&populate[league][populate]=Logo'
      '&populate[team][populate]=Logo'
      '&populate[game]=true'
      '&sort=Win:desc',
    );
    return _cachedGet<List<dynamic>>(
      uri,
      parse: (json) => (json['data'] as List<dynamic>?) ?? const [],
    );
  }

  /// Fetch matches for a specific team (home + away, de-duplicated).
  static Future<List<dynamic>> fetchTeamMatches(int teamId) async {
    final homeUri = Uri.parse(
      '$baseUrl/matches'
      '?filters[HomeTeam][id][\$eq]=$teamId'
      '&populate[HomeTeam][populate]=Logo'
      '&populate[AwayTeam][populate]=Logo'
      '&populate[League][populate]=Logo'
      '&populate[game]=true'
      '&populate[jornada]=true',
    );
    final awayUri = Uri.parse(
      '$baseUrl/matches'
      '?filters[AwayTeam][id][\$eq]=$teamId'
      '&populate[HomeTeam][populate]=Logo'
      '&populate[AwayTeam][populate]=Logo'
      '&populate[League][populate]=Logo'
      '&populate[game]=true'
      '&populate[jornada]=true',
    );

    final homeFuture = _cachedGet<List<dynamic>>(
      homeUri,
      parse: (json) => (json['data'] as List<dynamic>?) ?? const [],
    );
    final awayFuture = _cachedGet<List<dynamic>>(
      awayUri,
      parse: (json) => (json['data'] as List<dynamic>?) ?? const [],
    );

    final results = await Future.wait([homeFuture, awayFuture]);
    final allMatches = <dynamic>[...results[0], ...results[1]];

    // De-duplicate by documentId (falling back to id).
    final seen = <dynamic>{};
    allMatches.retainWhere((m) => seen.add(m['documentId'] ?? m['id']));
    return allMatches;
  }

  // ========== Playoffs ==========

  /// Lightweight wrapper for League meta-info needed by the Liga page to
  /// decide between standings and bracket layout.
  ///
  /// [status] is the raw `LeagueStatus` enum value (e.g. 'Standings' or
  /// 'Playoff'). [size] is the parsed `PlayoffSize` if it is set.
  /// We accept multiple casings of the field names because Strapi field
  /// naming varies between projects.
  static Future<({String? status, PlayoffSize? size})> fetchLeagueDetails(
    int leagueId,
  ) async {
    // Strapi v5 requires documentId for /leagues/:id, but we only have the
    // numeric id from the home page. Use a filtered findMany instead — works
    // on both v4 and v5 with the numeric id.
    final uri = Uri.parse(
      '$baseUrl/leagues?filters[id][\$eq]=$leagueId',
    );
    return _cachedGet<({String? status, PlayoffSize? size})>(
      uri,
      parse: (json) {
        final list = json['data'];
        if (list is! List || list.isEmpty || list.first is! Map) {
          debugPrint(
            'ApiService.fetchLeagueDetails(id=$leagueId): no league found',
          );
          return (status: null, size: null);
        }
        final m = list.first as Map<String, dynamic>;
        // Accept several casings to be defensive against schema renames.
        final status = (m['LeagueStatus'] ??
                m['leagueStatus'] ??
                m['leaguestatus'])
            ?.toString();
        final sizeRaw = (m['PlayoffSize'] ??
                m['playoffSize'] ??
                m['playoffsize'])
            ?.toString();
        debugPrint(
          'ApiService.fetchLeagueDetails(id=$leagueId): '
          'status=$status, sizeRaw=$sizeRaw',
        );
        return (status: status, size: PlayoffSize.fromApi(sizeRaw));
      },
    );
  }

  /// Fetch a single Playoff entry with full details (teams, players, logos).
  ///
  /// Mirrors the populate spec used by [fetchMatchDetails] so the result can be
  /// fed directly into `Match.fromJson` for display in the existing match
  /// detail screen. Strapi v5 uses `documentId` for findOne URLs.
  static Future<Map<String, dynamic>> fetchPlayoffMatchDetails(
    String documentId,
  ) async {
    if (documentId.isEmpty) {
      throw Exception('Playoff documentId is required');
    }
    final uri = Uri.parse(
      '$baseUrl/playoffs/$documentId'
      '?populate[HomeTeam][populate][Logo]=true'
      '&populate[HomeTeam][populate][players][populate]=*'
      '&populate[AwayTeam][populate][Logo]=true'
      '&populate[AwayTeam][populate][players][populate]=*'
      '&populate[league]=true'
      '&populate[game]=true',
    );
    return _cachedGet<Map<String, dynamic>>(
      uri,
      parse: (json) {
        final data = json['data'];
        if (data is! Map) {
          throw Exception('Unexpected playoff response shape');
        }
        return Map<String, dynamic>.from(data);
      },
    );
  }

  /// Fetch the playoff bracket entries for a given league + game.
  ///
  /// Results are returned grouped by [PlayoffStage] in display order. Stages
  /// without entries simply yield an empty list; the UI is responsible for
  /// rendering empty/TBD slots.
  static Future<Map<PlayoffStage, List<PlayoffMatch>>> fetchPlayoffMatches(
    int leagueId,
    int gameId,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/playoffs'
      '?filters[league][id][\$eq]=$leagueId'
      '&filters[game][id][\$eq]=$gameId'
      '&populate[HomeTeam][populate]=Logo'
      '&populate[AwayTeam][populate]=Logo'
      '&populate[league]=true'
      '&populate[game]=true'
      '&sort=id:asc',
    );
    return _cachedGet<Map<PlayoffStage, List<PlayoffMatch>>>(
      uri,
      parse: (json) {
        final List<dynamic> data = json['data'] ?? const [];
        debugPrint(
          'ApiService.fetchPlayoffMatches: ${data.length} entries '
          'for league=$leagueId, game=$gameId',
        );
        final grouped = <PlayoffStage, List<PlayoffMatch>>{
          for (final s in PlayoffStage.values) s: <PlayoffMatch>[],
        };
        for (final raw in data) {
          if (raw is! Map) continue;
          final m = PlayoffMatch.fromJson(raw as Map<String, dynamic>);
          if (m.stage != null) {
            grouped[m.stage!]!.add(m);
          }
        }
        // Sort each stage by MatchNumber so the bracket renders in canonical
        // top-to-bottom order. Matches without a MatchNumber sink to the end.
        for (final list in grouped.values) {
          list.sort((a, b) {
            final an = a.matchNumber;
            final bn = b.matchNumber;
            if (an == null && bn == null) return 0;
            if (an == null) return 1;
            if (bn == null) return -1;
            return an.compareTo(bn);
          });
        }
        return grouped;
      },
    );
  }
}
