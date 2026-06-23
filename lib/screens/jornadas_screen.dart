import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import '../selection_provider.dart';
import '../models/jornada.dart';
import '../widgets/home_fab.dart';
import '../widgets/league_nav_tabs.dart';
import '../widgets/page_dots_indicator.dart';
import 'match_detail_screen.dart';

class JornadasPage extends StatelessWidget {
  final String gameName;
  final String leagueName;

  const JornadasPage({
    super.key,
    required this.gameName,
    required this.leagueName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TelaJornadas(
        gameName: gameName,
        leagueName: leagueName,
      ),
    );
  }
}

class TelaJornadas extends StatefulWidget {
  final String gameName;
  final String leagueName;

  const TelaJornadas({
    super.key,
    required this.gameName,
    required this.leagueName,
  });

  @override
  State<TelaJornadas> createState() => _TelaJornadasState();
}

class _TelaJornadasState extends State<TelaJornadas> {
  int _currentJornadaIndex = 0;
  List<Jornada> _jornadas = [];
  bool _isLoading = true;
  String? _errorMessage;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchJornadas();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Pull-to-refresh: bust the cache and re-fetch jornadas.
  Future<void> _refresh() async {
    ApiService.clearCache();
    await _fetchJornadas();
  }

  /// Wraps scrollable page content in a themed [RefreshIndicator].
  Widget _wrapRefresh(Widget child) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF00FFFF),
      backgroundColor: const Color(0xFF000033),
      child: child,
    );
  }

  Future<void> _fetchJornadas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final selectionProvider = context.read<SelectionProvider>();
      final jornadas = await ApiService.fetchJornadas(
        selectionProvider.selectedLeagueId,
        selectionProvider.selectedGameId,
      );

      if (!mounted) return;
      setState(() {
        _jornadas = jornadas;
        _currentJornadaIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching jornadas: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load jornadas: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF000033),
      child: Stack(
        children: [
          // ========== PAGE CONTENT WITH SWIPE DETECTION ==========
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            bottom: 83,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00FFFF),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : _jornadas.isEmpty
                        ? const Center(
                            child: Text(
                              'No matches scheduled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentJornadaIndex = index;
                              });
                            },
                            itemCount: _jornadas.length,
                            itemBuilder: (context, index) {
                              return _wrapRefresh(SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  children: [
                                    // ========== LEAGUE INFO HEADER ==========
                                    Container(
                                      width: double.infinity,
                                      color: const Color(0xFF000033),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          // League Logo
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              color: Colors.grey.withValues(alpha: 0.2),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(3),
                                              child: _jornadas[index].leagueLogoUrl != null
                                                ? Image.network(
                                                    _jornadas[index].leagueLogoUrl!,
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.sports_esports,
                                                        color: Colors.white54,
                                                        size: 24,
                                                      );
                                                    },
                                                  )
                                                : const Icon(
                                                    Icons.sports_esports,
                                                    color: Colors.white54,
                                                    size: 24,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // League Name & Season
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                widget.leagueName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                widget.gameName,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.6),
                                                  fontSize: 11,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                  // ========== JORNADA INFO (NO NAVIGATION BUTTONS) ==========
                                  Container(
                                    width: double.infinity,
                                    height: 2,
                                    color: const Color(0xFFFF00FF),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    color: const Color(0xFF000033),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _jornadas[index].name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (_jornadas[index].startDate != null)
                                            Text(
                                              _jornadas[index].startDate!,
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.6),
                                                fontSize: 11,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 2,
                                    color: const Color(0xFFFF00FF),
                                  ),

                                  // ========== MATCH GRID ==========
                                  if (_jornadas[index].matches.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No matches for this jornada',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else
                                    ..._jornadas[index].matches
                                        .map((match) => _buildMatchRow(match)),
                                  Container(
                                    width: double.infinity,
                                    height: 2,
                                    color: const Color(0xFFFF00FF),
                                  ),
                                ],
                              ),
                            ));
                            },
                          ),
          ),

          // ========== BOTTOM NAVBAR ==========
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 83,
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
                  // Pagination Dots (showing Jornada progress)
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
                      pageCount: _jornadas.length,
                      currentPage: _currentJornadaIndex,
                      onDotTap: (index) => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                  // Navigation Tabs
                  Expanded(
                    child: LeagueNavTabs(
                      active: LeagueNavTab.jornadas,
                      gameName: widget.gameName,
                      leagueName: widget.leagueName,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========== HOME BUTTON (top-left) ==========
          Positioned(
            top: statusBarHeight + 8,
            left: 12,
            child: const HomeFab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRow(Match match) {
    // Helper function to build team logo or placeholder
    Widget buildTeamLogo(String? logoUrl) {
      if (logoUrl != null && logoUrl.isNotEmpty) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            image: DecorationImage(
              image: NetworkImage(logoUrl),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {
                // Fallback if image fails to load
              },
            ),
          ),
        );
      } else {
        // Fallback placeholder
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey[800],
          ),
          child: const Icon(
            Icons.image_not_supported,
            color: Colors.white,
            size: 16,
          ),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to MatchDetailScreen with documentId
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailScreen(
                documentId: match.documentId,
              ),
            ),
          );
        },
        splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
        highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 60,
              color: const Color(0xFF000033),
              child: Row(
                children: [
                  // Left Column - Team 1 with Logo
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              match.homeTeamName,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          buildTeamLogo(match.homeTeamLogoUrl),
                        ],
                      ),
                    ),
                  ),
                  // Center Column - Time/Format
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 2,
                            color: Color(0xFFFF00FF),
                          ),
                          right: BorderSide(
                            width: 2,
                            color: Color(0xFFFF00FF),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Finished: show result in cyan
                          if (match.status != null && match.status!.toLowerCase() == 'finished')
                            Text(
                              '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                              style: const TextStyle(
                                color: Color(0xFF00FFFF),
                                fontSize: 15,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          // Live: show result in red
                          else if (match.status != null && match.status!.toLowerCase() == 'live')
                            Text(
                              '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
                              style: const TextStyle(
                                color: Color(0xFFFF0000),
                                fontSize: 15,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          // Scheduled (or unknown): show local time HH:mm
                          else if (match.formattedTime != null)
                            Text(
                              match.formattedTime!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (match.format != null)
                            Text(
                              match.format!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Right Column - Team 2 with Logo
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          buildTeamLogo(match.awayTeamLogoUrl),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              match.awayTeamName,
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 2,
              color: const Color(0xFFFF00FF),
            ),
          ],
        ),
      ),
    );
  }
}
