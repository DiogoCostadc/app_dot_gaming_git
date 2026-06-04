import 'package:flutter/material.dart';
import '../models/match.dart';
import '../api_service.dart';
import '../widgets/page_dots_indicator.dart';
import 'liga_screen.dart';
import '../config.dart';
import 'match_detail_screen.dart';

class TeamDetailPage extends StatefulWidget {
  final Team team;
  final String gameName;
  const TeamDetailPage({super.key, required this.team, required this.gameName});
  @override State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentTabIndex = 0;

  late Future<List<Player>> _playersFuture;
  late Future<List<Map<String, dynamic>>> _standingsFuture;
  late Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController();
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
        _pageController.animateToPage(_currentTabIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    });
    _playersFuture = _fetchPlayers();
    _standingsFuture = _fetchStandings();
    _matchesFuture = _fetchMatches();
  }

  Future<List<Player>> _fetchPlayers() async {
    debugPrint('Fetching players for team: ${widget.team.name}, id: ${widget.team.id}');
    if (widget.team.players.isNotEmpty) {
      debugPrint('Using cached players: ${widget.team.players.length}');
      return widget.team.players;
    }
    try {
      final data = await ApiService.fetchTeamPlayers(widget.team.id);
      debugPrint('API returned ${data.length} player records');
      if (data.isEmpty) {
        debugPrint('No players returned from API');
        return [];
      }
      final players = data.map((p) {
        debugPrint('Parsing player: $p');
        return Player.fromJson(p as Map<String, dynamic>);
      }).toList();
      debugPrint('Parsed ${players.length} players');
      return players;
    } catch (e) {
      debugPrint('Error in _fetchPlayers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStandings() async {
    final data = await ApiService.fetchTeamStandings(widget.team.id);
    return data.map((s) {
      String leagueName = 'Unknown';
      String? leagueLogoUrl;
      if (s['league'] != null && s['league'] is Map) {
        final league = s['league'] as Map<String, dynamic>;
        leagueName = league['Name'] ?? 'Unknown';
        if (league['Logo'] != null && league['Logo'] is Map) {
          final url = league['Logo']['url'];
          if (url != null) {
            leagueLogoUrl = resolveMediaUrl(url.toString());
          }
        }
      }
      String gameName = '';
      if (s['game'] != null && s['game'] is Map) {
        gameName = (s['game'] as Map<String, dynamic>)['Name']?.toString() ?? '';
      }
      return {
        'leagueName': leagueName,
        'leagueLogoUrl': leagueLogoUrl ?? '',
        'gameName': gameName,
        'wins': s['Win'] ?? 0,
        'losses': s['Losses'] ?? 0,
        'winRounds': s['WinRounds'] ?? 0,
        'lossRounds': s['LossRounds'] ?? 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchMatches() async {
    final data = await ApiService.fetchTeamMatches(widget.team.id);
    return data.map((m) {
      String home = 'Unknown';
      String away = 'Unknown';
      String? homeLogo;
      String? awayLogo;
      String? leagueName;
      String? dateStr;

      if (m['HomeTeam'] != null && m['HomeTeam'] is Map) {
        final ht = m['HomeTeam'] as Map<String, dynamic>;
        home = ht['Name'] ?? 'Unknown';
        if (ht['Logo'] != null && ht['Logo'] is Map) {
          final url = ht['Logo']['url'];
          if (url != null) homeLogo = resolveMediaUrl(url.toString());
        }
      }
      if (m['AwayTeam'] != null && m['AwayTeam'] is Map) {
        final at = m['AwayTeam'] as Map<String, dynamic>;
        away = at['Name'] ?? 'Unknown';
        if (at['Logo'] != null && at['Logo'] is Map) {
          final url = at['Logo']['url'];
          if (url != null) awayLogo = resolveMediaUrl(url.toString());
        }
      }
      if (m['League'] != null && m['League'] is Map) {
        final lg = m['League'] as Map<String, dynamic>;
        leagueName = lg['Name'] ?? 'Unknown';
      }
      String gameName = '';
      if (m['game'] != null && m['game'] is Map) {
        gameName = (m['game'] as Map<String, dynamic>)['Name']?.toString() ?? '';
      }
      String? jornadaLabel;
      int? jornadaNumber;
      final jornada = m['jornada'];
      if (jornada is Map) {
        final name = jornada['Name']?.toString();
        final number = jornada['Number'];
        if (number is int) {
          jornadaNumber = number;
        } else if (number is num) {
          jornadaNumber = number.toInt();
        } else if (number is String) {
          jornadaNumber = int.tryParse(number);
        }
        if (name != null && name.trim().isNotEmpty) {
          jornadaLabel = name;
        } else if (jornadaNumber != null) {
          jornadaLabel = 'Jornada $jornadaNumber';
        }
      }
      dateStr = m['DateTime'] as String?;

      return {
        'documentId': m['documentId'] ?? '',
        'home': home,
        'away': away,
        'homeLogo': homeLogo,
        'awayLogo': awayLogo,
        'leagueName': leagueName ?? 'Competição',
        'gameName': gameName,
        'jornada': jornadaLabel,
        'jornadaNumber': jornadaNumber,
        'date': dateStr,
        'status': m['Matchstatus'] as String?,
        'homeScore': m['HomeScore'] as int?,
        'awayScore': m['AwayScore'] as int?,
      };
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentTabIndex = index);
    _tabController.animateTo(index);
  }

  void _onDotTap(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      body: SafeArea(
        child: Column(children: [
          _buildAppBar(),
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildJogadoresTab(),
                _buildClassificacaoTab(),
                _buildPartidasTab(),
                _buildTrofeusTab(),
              ],
            ),
          ),
          _buildBottomDots(),
        ]),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(width: 2, color: Color(0xB5FD01FA)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
              child: Container(
                  width: 60,
                  height: double.infinity,
                  padding: const EdgeInsets.all(15),
                  child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 32)
                      ])),
            ),
          ),
          const Expanded(
              child: Text('Equipa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 60, height: double.infinity),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.withValues(alpha: 0.2)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.team.logo.isNotEmpty
                  ? Image.network(widget.team.logo,
                      width: 100, height: 100, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                          Icons.sports_esports,
                          color: Colors.white54,
                          size: 48))
                  : const Icon(Icons.sports_esports,
                      color: Colors.white54, size: 48),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.team.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(widget.gameName,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(width: 2, color: Color(0xFFE000FF)))),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFE000FF),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400, fontFamily: 'Inter'),
        tabs: const [
          Tab(text: 'Jogadores'),
          Tab(text: 'Classificação'),
          Tab(text: 'Partidas'),
          Tab(text: 'Troféus'),
        ],
      ),
    );
  }

  Widget _buildJogadoresTab() {
    return FutureBuilder<List<Player>>(
      future: _playersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE000FF)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar jogadores:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }
        final players = snapshot.data ?? [];
        if (players.isEmpty) {
          return const Center(
              child: Text('Nenhum jogador encontrado',
                  style: TextStyle(color: Colors.white54, fontSize: 16)));
        }
        // Group players by game; players with no game info land in 'Outros'.
        final grouped = <String, List<Player>>{};
        for (final p in players) {
          final key = (p.gameName != null && p.gameName!.trim().isNotEmpty)
              ? p.gameName!.trim()
              : 'Outros';
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(p);
        }
        final groups = grouped.entries.toList()
          ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, gIndex) {
            final group = groups[gIndex];
            return Padding(
              padding: EdgeInsets.only(bottom: gIndex == groups.length - 1 ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header (game name)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      group.key,
                      style: const TextStyle(
                        color: Color(0xFF00FFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...group.value.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A1A4A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE000FF).withValues(alpha: 0.3),
                              width: 1)),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                                color: const Color(0xFFE000FF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(22)),
                            child: const Icon(Icons.person,
                                color: Color(0xFFE000FF), size: 24)),
                        title: Text(p.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        subtitle: p.role != null && p.role!.isNotEmpty
                            ? Text(p.role!,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13))
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE000FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('#${index + 1}',
                              style: const TextStyle(
                                  color: Color(0xFFE000FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClassificacaoTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _standingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE000FF)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar classificação:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(
              child: Text('Sem dados de classificação',
                  style: TextStyle(color: Colors.white54, fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, i) {
            final c = data[i];
            final wins = c['wins'] as int? ?? 0;
            final losses = c['losses'] as int? ?? 0;
            final winRounds = c['winRounds'] as int? ?? 0;
            final lossRounds = c['lossRounds'] as int? ?? 0;
            final diff = winRounds - lossRounds;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF1A1A4A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFE000FF).withValues(alpha: 0.3),
                      width: 1)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final leagueName = c['leagueName'] as String? ?? 'Unknown';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LigaPage(
                          gameName: widget.gameName,
                          leagueName: leagueName,
                        ),
                      ),
                    );
                  },
                  splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: c['leagueLogoUrl'] != null &&
                            (c['leagueLogoUrl'] as String).isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              c['leagueLogoUrl'] as String,
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFFE000FF),
                                  size: 28),
                            ),
                          )
                        : const Icon(Icons.emoji_events,
                            color: Color(0xFFE000FF), size: 28),
                    title: Builder(builder: (_) {
                      final gameName = (c['gameName'] as String?) ?? '';
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              c['leagueName'] as String? ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (gameName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                gameName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                    subtitle: Text('$wins V - $losses D',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13)),
                    trailing: Text(
                      diff >= 0 ? '+$diff' : '$diff',
                      style: TextStyle(
                        color: diff >= 0
                            ? const Color(0xFF00FF00)
                            : const Color(0xFFFF6B6B),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPartidasTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE000FF)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar partidas:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }
        final matches = snapshot.data ?? [];
        if (matches.isEmpty) {
          return const Center(
              child: Text('Sem partidas agendadas',
                  style: TextStyle(color: Colors.white54, fontSize: 16)));
        }

        // Group matches by game (so the dropdown organizes the list per game).
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final m in matches) {
          final game = (m['gameName'] as String?)?.trim();
          final key = (game != null && game.isNotEmpty)
              ? game
              : (m['leagueName'] as String? ?? 'Outros');
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(m);
        }

        // Sort matches inside each game from oldest to most recent (Jornada 1
        // first). Falls back to the match date if the jornada number is
        // missing.
        for (final list in grouped.values) {
          list.sort((a, b) {
            final na = a['jornadaNumber'] as int?;
            final nb = b['jornadaNumber'] as int?;
            if (na != null && nb != null) return na.compareTo(nb);
            if (na != null) return -1;
            if (nb != null) return 1;
            final da = DateTime.tryParse((a['date'] as String?) ?? '');
            final db = DateTime.tryParse((b['date'] as String?) ?? '');
            if (da != null && db != null) return da.compareTo(db);
            return 0;
          });
        }

        final comps = grouped.entries.toList()
          ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

        // Build the children of the single ExpansionTile: each game gets its
        // own header followed by its match rows.
        final tileChildren = <Widget>[];
        for (var gi = 0; gi < comps.length; gi++) {
          final comp = comps[gi];
          tileChildren.add(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE000FF).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                comp.key,
                style: const TextStyle(
                  color: Color(0xFF00FFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
          tileChildren.addAll(comp.value.map(_buildMatchRow));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A4A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE000FF).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  iconColor: const Color(0xFFE000FF),
                  collapsedIconColor: Colors.white.withValues(alpha: 0.5),
                  title: const Text(
                    'Partidas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: EdgeInsets.zero,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  children: tileChildren,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchRow(Map<String, dynamic> m) {
    final home = m['home'] as String? ?? 'Unknown';
    final away = m['away'] as String? ?? 'Unknown';
    final dateStr = m['date'] as String?;
    final homeScore = m['homeScore'] as int?;
    final awayScore = m['awayScore'] as int?;
    final status = m['status'] as String?;

    String dateLabel = '';
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateStr).toLocal();
        dateLabel =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateLabel = dateStr;
      }
    }

    String scoreLabel = '';
    if (homeScore != null && awayScore != null) {
      scoreLabel = '$homeScore - $awayScore';
    } else if (status != null && status.isNotEmpty) {
      scoreLabel = status;
    } else if (dateLabel.isNotEmpty) {
      scoreLabel = dateLabel;
    }

    final docId = m['documentId'] as String? ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: docId.isNotEmpty
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MatchDetailScreen(documentId: docId),
                  ),
                );
              }
            : null,
        splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$home vs $away',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    if ((m['jornada'] as String?)?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          m['jornada'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                scoreLabel,
                style: const TextStyle(
                  color: Color(0xFF00FFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrofeusTab() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.emoji_events,
          size: 64, color: const Color(0xFFE000FF).withValues(alpha: 0.3)),
      const SizedBox(height: 16),
      Text('Histórico de Competições',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Em breve disponível',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
    ]));
  }

  Widget _buildBottomDots() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border:
              Border(top: BorderSide(width: 2, color: Color(0xFFE000FF)))),
      child: PageDotsIndicator(
        pageCount: 4,
        currentPage: _currentTabIndex,
        onDotTap: _onDotTap,
      ),
    );
  }
}
