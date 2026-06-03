import 'package:flutter/material.dart';
import '../models/match.dart';
import '../widgets/page_dots_indicator.dart';
import '../widgets/player_list.dart';
import 'team_detail_screen.dart';
import '../widgets/stream_player.dart';
import '../api_service.dart';

class MatchDetailScreen extends StatefulWidget {
  final String documentId;

  /// When true, fetches the match from the `/playoffs/:documentId` endpoint
  /// instead of `/matches/:documentId`. The rendered UI is identical — only
  /// the data source differs.
  final bool isPlayoff;

  const MatchDetailScreen({
    super.key,
    required this.documentId,
    this.isPlayoff = false,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<Match> _matchFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _matchFuture = _fetchMatchDetails();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatMatchHour(String dateTime) {
    if (dateTime.isEmpty) return '';
    try {
      final date = DateTime.parse(dateTime);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  Future<Match> _fetchMatchDetails() async {
    final matchData = widget.isPlayoff
        ? await ApiService.fetchPlayoffMatchDetails(widget.documentId)
        : await ApiService.fetchMatchDetails(widget.documentId);
    return Match.fromJson(matchData);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      body: FutureBuilder<Match>(
        future: _matchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                // Top Navigation Bar
                Container(
                  width: double.infinity,
                  height: 76 + statusBarHeight,
                  padding: EdgeInsets.only(top: statusBarHeight),
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: Color(0xB5FD01FA),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                          highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
                          child: Container(
                            width: 60,
                            height: double.infinity,
                            padding: const EdgeInsets.all(15),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, color: Colors.white, size: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Title
                      const Expanded(
                        child: Text(
                          'Partida',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 60, height: double.infinity),
                    ],
                  ),
                ),
                // Loading Content
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFF00FF)),
                        SizedBox(height: 16),
                        Text(
                          'Carregando detalhes da partida...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Column(
              children: [
                // Top Navigation Bar
                Container(
                  width: double.infinity,
                  height: 76 + statusBarHeight,
                  padding: EdgeInsets.only(top: statusBarHeight),
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: Color(0xB5FD01FA),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 60,
                            height: double.infinity,
                            padding: const EdgeInsets.all(15),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, color: Colors.white, size: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Partida',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 60, height: double.infinity),
                    ],
                  ),
                ),
                // Error Content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Erro ao carregar partida',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _matchFuture = _fetchMatchDetails();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF00FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'Nenhum dado encontrado',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final match = snapshot.data!;
          
          return SafeArea(
            child: Column(
              children: [
              // Top Navigation Bar (similar to main app)
              Container(
                width: double.infinity,
                height: 76 + statusBarHeight,
                padding: EdgeInsets.only(top: statusBarHeight),
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: Color(0xB5FD01FA),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                        highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
                        child: Container(
                          width: 60,
                          height: double.infinity,
                          padding: const EdgeInsets.all(15),
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back, color: Colors.white, size: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Title
                    const Expanded(
                      child: Text(
                        'Partida',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 60, height: double.infinity),
                  ],
                ),
              ),
              
              // Match Header - Large (1/3 of page) with Logos
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Teams with Logos and Scores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Home Team Column (Left Side)
                        Expanded(
                          flex: 1,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeamDetailPage(
                                      team: match.homeTeam,
                                      gameName: match.leagueName,
                                    ),
                                  ),
                                );
                              },
                              splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                              child: Column(
                                children: [
                                  // Team Logo
                                  Container(
                                    width: 120,
                                    height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: match.homeTeam.logo.isNotEmpty
                                    ? Image.network(
                                        match.homeTeam.logo,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.grey.withValues(alpha: 0.3),
                                            ),
                                            child: const Icon(
                                              Icons.sports_soccer,
                                              color: Colors.white54,
                                              size: 48,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                        child: const Icon(
                                          Icons.sports_soccer,
                                          color: Colors.white54,
                                          size: 48,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Score (no dash)
                              Text(
                                match.homeScore.toString(),
                                style: TextStyle(
                                  color: match.matchStatus == 'Live' 
                                      ? Colors.red 
                                      : const Color(0xFF00FFFF),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Team Name
                              Text(
                                match.homeTeam.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                            ),
                          ),
                        ),
                        
                        // Center Match Type, Status, and Dash
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Match hour for scheduled matches
                            if (match.matchStatus == 'Upcoming' || match.matchStatus == 'Scheduled')
                              Text(
                                _formatMatchHour(match.dateTime),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            // Match type
                            Text(
                              match.type,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: match.matchStatus == 'Live' 
                                    ? Colors.red.withValues(alpha: 0.8)
                                    : Colors.grey.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                match.matchStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Dash separator
                            const Text(
                              '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Away Team Column (Right Side)
                        Expanded(
                          flex: 1,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeamDetailPage(
                                      team: match.awayTeam,
                                      gameName: match.leagueName,
                                    ),
                                  ),
                                );
                              },
                              splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
                              child: Column(
                                children: [
                                  // Team Logo
                                  Container(
                                    width: 120,
                                    height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: match.awayTeam.logo.isNotEmpty
                                    ? Image.network(
                                        match.awayTeam.logo,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: Colors.grey.withValues(alpha: 0.3),
                                            ),
                                            child: const Icon(
                                              Icons.sports_soccer,
                                              color: Colors.white54,
                                              size: 48,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                        child: const Icon(
                                          Icons.sports_soccer,
                                          color: Colors.white54,
                                          size: 48,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Score (no dash)
                              Text(
                                match.awayScore.toString(),
                                style: TextStyle(
                                  color: match.matchStatus == 'Live' 
                                      ? Colors.red 
                                      : const Color(0xFF00FFFF),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Team Name
                              Text(
                                match.awayTeam.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Dividing Stroke Line
              Container(
                width: double.infinity,
                height: 2,
                color: const Color(0xB5FD01FA),
              ),
              
              // Tab Content
              Expanded(
                child: Column(
                  children: [
                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Players List Tab
                          PlayerList(match: match),
                          // Twitch Stream Tab
                          StreamPlayer(match: match),
                        ],
                      ),
                    ),
                    
                    // Stroke Line Above Tab Indicators
                    Container(
                      width: double.infinity,
                      height: 2,
                      color: const Color(0xB5FD01FA),
                    ),
                    
                    // Tab Indicators (Neon Dots) - Moved to Bottom
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: PageDotsIndicator(
                        pageCount: _tabController.length,
                        currentPage: _tabController.index,
                        onDotTap: (index) => _tabController.animateTo(index),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  }
}
