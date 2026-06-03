import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../selection_provider.dart';
import '../api_service.dart';
import '../models/match.dart';
import '../models/playoff.dart';
import '../models/standing.dart';
import '../widgets/home_fab.dart';
import '../widgets/leaderboard_header.dart';
import '../widgets/league_nav_tabs.dart';
import '../widgets/page_dots_indicator.dart';
import 'team_detail_screen.dart';

/// Combined payload powering the Liga page: league meta-info (used to decide
/// between standings table and playoff bracket), the standings list, and
/// the playoff bracket entries grouped by stage.
typedef _LigaData = ({
  ({String? status, PlayoffSize? size}) leagueDetails,
  List<Standing> standings,
  Map<PlayoffStage, List<PlayoffMatch>> playoffMatches,
});

class LigaPage extends StatelessWidget {
  final String gameName;
  final String leagueName;

  const LigaPage({
    super.key,
    required this.gameName,
    required this.leagueName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaginaDaLigaClassificaO(
        gameName: gameName,
        leagueName: leagueName,
      ),
    );
  }
}

class PaginaDaLigaClassificaO extends StatefulWidget {
  final String gameName;
  final String leagueName;

  const PaginaDaLigaClassificaO({
    super.key,
    required this.gameName,
    required this.leagueName,
  });

  @override
  State<PaginaDaLigaClassificaO> createState() =>
      _PaginaDaLigaClassificaOState();
}

class _PaginaDaLigaClassificaOState extends State<PaginaDaLigaClassificaO> {
  late Future<_LigaData> _futureLigaData;
  late final PageController _pageController;
  int _currentPage = 0;

  /// Whether the current game has a second leaderboard page (rounds/matches stats).
  bool get _hasStatsPage {
    final g = widget.gameName.toLowerCase().trim();
    return g == 'counter-strike 2' ||
        g == 'valorant' ||
        g == 'rocket league' ||
        g == 'rocket-league';
  }

  /// Whether the second page should be labelled as 'matches' (Rocket League)
  /// instead of 'rounds' (CS2 / Valorant).
  bool get _isMatchesGame {
    final g = widget.gameName.toLowerCase().trim();
    return g == 'rocket league' || g == 'rocket-league';
  }

  /// Number of teams (from the top of the standings) that qualify for playoffs.
  /// Valorant takes 4 teams; the other supported games take 3.
  int get _playoffQualifiedCount {
    final g = widget.gameName.toLowerCase().trim();
    return g == 'valorant' ? 4 : 3;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Get league and game IDs from provider
    final selectionProvider = context.read<SelectionProvider>();
    _futureLigaData = _loadLigaData(
      selectionProvider.selectedLeagueId,
      selectionProvider.selectedGameId,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Standing>> fetchStandings(int? leagueId, int? gameId) async {
    return ApiService.fetchStandings(leagueId, gameId);
  }

  /// Fetch league meta-info, standings and playoff matches concurrently.
  ///
  /// All three are queried regardless of mode because they are cached, so
  /// switching between standings and bracket later doesn't trigger a refetch.
  /// After the data resolves, [_isPlayoffMode] is updated so the surrounding
  /// layout (bottom-nav dots, etc.) can adapt.
  Future<_LigaData> _loadLigaData(int? leagueId, int? gameId) async {
    if (leagueId == null || gameId == null) {
      throw Exception('League ID and Game ID are required');
    }
    final results = await Future.wait([
      ApiService.fetchLeagueDetails(leagueId),
      ApiService.fetchStandings(leagueId, gameId),
      ApiService.fetchPlayoffMatches(leagueId, gameId),
    ]);
    final data = (
      leagueDetails: results[0] as ({String? status, PlayoffSize? size}),
      standings: results[1] as List<Standing>,
      playoffMatches: results[2] as Map<PlayoffStage, List<PlayoffMatch>>,
    );
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF000031),
      child: Stack(
        children: [
          // ========== PAGE CONTENT ==========
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            bottom: _hasStatsPage ? 83 : 55,
            child: FutureBuilder<_LigaData>(
              future: _futureLigaData,
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
                          'Error loading standings',
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
                              final selectionProvider = context.read<SelectionProvider>();
                              if (selectionProvider.selectedLeagueId != null && selectionProvider.selectedGameId != null) {
                                _futureLigaData = _loadLigaData(
                                  selectionProvider.selectedLeagueId,
                                  selectionProvider.selectedGameId,
                                );
                              }
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
                } else if (!snapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No data found',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Please select a league and game',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!;
                final standings = data.standings;
                if (standings.isEmpty) {
                  return const Center(
                    child: Text(
                      'No standings found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!_hasStatsPage) {
                  return _buildFirstLeaderboardPage(standings);
                }

                return PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildFirstLeaderboardPage(standings),
                    _buildSecondLeaderboardPage(standings),
                  ],
                );
              },
            ),
          ),

          // ========== BOTTOM NAVBAR ==========
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _hasStatsPage ? 83 : 55,
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0x332B2626),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_hasStatsPage)
                    Container(
                      width: double.infinity,
                      height: 28,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE000FF), width: 2),
                          bottom: BorderSide(color: Color(0xFFE000FF), width: 2),
                        ),
                      ),
                      child: PageDotsIndicator(
                        pageCount: 2,
                        currentPage: _currentPage,
                        onDotTap: (index) => _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 2,
                      color: const Color(0xFFE000FF),
                    ),
                  Expanded(
                    child: LeagueNavTabs(
                      active: LeagueNavTab.classificacao,
                      gameName: widget.gameName,
                      leagueName: widget.leagueName,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========== HOME FAB ==========
          Positioned(
            right: 16,
            bottom: (_hasStatsPage ? 83 : 55) + 16,
            child: const HomeFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(
    String seed,
    String team,
    String wins,
    String losses,
    Team? teamObj,
    String gameName, {
    bool? qualified,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _qualificationTint(qualified),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE000FF), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildQualificationStripe(qualified),
          Expanded(flex: 1, child: _buildTableCell(seed)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: teamObj != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamDetailPage(
                              team: teamObj,
                              gameName: gameName,
                            ),
                          ),
                        );
                      }
                    : null,
                splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                child: _buildTableCell(team),
              ),
            ),
          ),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(wins)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(losses)),
        ],
      ),
    );
  }

  /// Variant of [_buildLeaderboardRow] for games that include Draws and Points
  /// columns (currently Rocket League). Layout:
  /// Seed | Equipa | Vitorias | Empates | Derrotas | Pontos
  Widget _buildLeaderboardRowWithExtras({
    required String seed,
    required String team,
    required String wins,
    required String draws,
    required String losses,
    required String points,
    required Team? teamObj,
    required String gameName,
    bool? qualified,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _qualificationTint(qualified),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE000FF), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildQualificationStripe(qualified),
          Expanded(flex: 1, child: _buildTableCell(seed)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: teamObj != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamDetailPage(
                              team: teamObj,
                              gameName: gameName,
                            ),
                          ),
                        );
                      }
                    : null,
                splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                child: _buildTableCell(team),
              ),
            ),
          ),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(wins)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(draws)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(losses)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(points)),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Row background tint based on whether the team qualifies for playoffs.
  /// Returns null when [qualified] is null so non-applicable rows stay untinted.
  Color? _qualificationTint(bool? qualified) {
    if (qualified == null) return null;
    return qualified
        ? const Color(0xFF00FF66).withValues(alpha: 0.18)
        : const Color(0xFFFF4D4D).withValues(alpha: 0.14);
  }

  /// Coloured vertical stripe shown at the leftmost edge of each standings row
  /// to indicate playoff qualification status (green = in, red = out).
  Widget _buildQualificationStripe(bool? qualified) {
    if (qualified == null) return const SizedBox.shrink();
    return Container(
      width: 6,
      decoration: BoxDecoration(
        color: qualified
            ? const Color(0xFF00FF66)
            : const Color(0xFFFF4D4D),
        boxShadow: [
          BoxShadow(
            color: (qualified
                    ? const Color(0xFF00FF66)
                    : const Color(0xFFFF4D4D))
                .withValues(alpha: 0.8),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildFirstLeaderboardPage(List<Standing> standings) {
    final leagueLogo = standings.isNotEmpty ? standings.first.leagueLogoUrl : '';
    return SingleChildScrollView(
      child: Column(
        children: [
          LeaderboardHeader(
            gameName: widget.gameName,
            leagueName: widget.leagueName,
            logoUrl: leagueLogo,
          ),
          const Divider(color: Color(0xFFE000FF), thickness: 2, height: 0),
          const LeaderboardSectionTitle('Classificação'),

          // Table Header
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE000FF), width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildTableHeaderCell('Seed')),
                Container(width: 2, color: const Color(0xFFE000FF)),
                Expanded(flex: 2, child: _buildTableHeaderCell('Equipa')),
                Container(width: 2, color: const Color(0xFFE000FF)),
                Expanded(flex: 1, child: _buildTableHeaderCell('Vitorias')),
                if (_isMatchesGame) ...[
                  Container(width: 2, color: const Color(0xFFE000FF)),
                  Expanded(flex: 1, child: _buildTableHeaderCell('Empates')),
                ],
                Container(width: 2, color: const Color(0xFFE000FF)),
                Expanded(flex: 1, child: _buildTableHeaderCell('Derrotas')),
                if (_isMatchesGame) ...[
                  Container(width: 2, color: const Color(0xFFE000FF)),
                  Expanded(flex: 1, child: _buildTableHeaderCell('Pontos')),
                ],
              ],
            ),
          ),

          // Data Grid - Dynamic based on standings
          ...standings.asMap().entries.map((entry) {
            int index = entry.key + 1;
            Standing standing = entry.value;
            final teamObj = standing.teamId != null
                ? Team(
                    id: standing.teamId!,
                    name: standing.teamName,
                    logo: standing.teamLogoUrl ?? '',
                    players: [],
                  )
                : null;

            final qualified = index <= _playoffQualifiedCount;

            if (_isMatchesGame) {
              return _buildLeaderboardRowWithExtras(
                seed: index.toString(),
                team: standing.teamName,
                wins: standing.wins.toString(),
                draws: standing.draws.toString(),
                losses: standing.losses.toString(),
                points: standing.points.toString(),
                teamObj: teamObj,
                gameName: widget.gameName,
                qualified: qualified,
              );
            }

            return _buildLeaderboardRow(
              index.toString(),
              standing.teamName,
              standing.wins.toString(),
              standing.losses.toString(),
              teamObj,
              widget.gameName,
              qualified: qualified,
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSecondLeaderboardPage(List<Standing> standings) {
    final leagueLogo =
        standings.isNotEmpty ? standings.first.leagueLogoUrl : '';
    final sectionTitle = _isMatchesGame
        ? 'Estatísticas de Partidas'
        : 'Estatísticas de Rondas';

    return SingleChildScrollView(
      child: Column(
        children: [
          LeaderboardHeader(
            gameName: widget.gameName,
            leagueName: widget.leagueName,
            logoUrl: leagueLogo,
          ),
          const Divider(color: Color(0xFFE000FF), thickness: 2, height: 0),
          LeaderboardSectionTitle(sectionTitle),

          // Table Header
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE000FF), width: 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildTableHeaderCell('Equipa')),
                Container(width: 2, color: const Color(0xFFE000FF)),
                Expanded(flex: 1, child: _buildTableHeaderCell('Ganhas')),
                Container(width: 2, color: const Color(0xFFE000FF)),
                Expanded(flex: 1, child: _buildTableHeaderCell('Perdidas')),
                Container(width: 2, color: const Color(0xFFE000FF)),
                Expanded(flex: 1, child: _buildTableHeaderCell('Diferença')),
              ],
            ),
          ),

          // Data Grid
          ...standings.map((standing) {
            final diff = standing.roundDifference;
            return _buildStatsRow(
              standing.teamName,
              standing.winRounds.toString(),
              standing.lossRounds.toString(),
              (diff > 0 ? '+' : '') + diff.toString(),
              standing.teamId != null
                  ? Team(
                      id: standing.teamId!,
                      name: standing.teamName,
                      logo: standing.teamLogoUrl ?? '',
                      players: [],
                    )
                  : null,
              widget.gameName,
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    String team,
    String ganhas,
    String perdidas,
    String diferenca,
    Team? teamObj,
    String gameName,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE000FF), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: teamObj != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamDetailPage(
                              team: teamObj,
                              gameName: gameName,
                            ),
                          ),
                        );
                      }
                    : null,
                splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                child: _buildTableCell(team),
              ),
            ),
          ),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(ganhas)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(flex: 1, child: _buildTableCell(perdidas)),
          Container(width: 2, color: const Color(0xFFE000FF)),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                diferenca,
                style: TextStyle(
                  color: diferenca.startsWith('+')
                      ? const Color(0xFF00FF00)
                      : const Color(0xFFFF6B6B),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
