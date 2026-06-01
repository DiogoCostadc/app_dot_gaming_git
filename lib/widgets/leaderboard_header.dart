import 'package:flutter/material.dart';

/// Shared header block used at the top of both leaderboard pages
/// (Classificação and Estatísticas de Rondas).
///
/// Displays the league logo, game name, league name, and season year.
class LeaderboardHeader extends StatelessWidget {
  final String gameName;
  final String leagueName;
  final String logoUrl;
  final String season;

  const LeaderboardHeader({
    super.key,
    required this.gameName,
    required this.leagueName,
    required this.logoUrl,
    this.season = '2026/2027',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // League Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: logoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      logoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.sports_esports,
                        color: Colors.yellow[700],
                        size: 40,
                      ),
                    ),
                  )
                : Icon(
                    Icons.sports_esports,
                    color: Colors.yellow[700],
                    size: 40,
                  ),
          ),
          const SizedBox(width: 16),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameName,
                  style: const TextStyle(
                    color: Color(0xFF9494B8),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  leagueName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  season,
                  style: const TextStyle(
                    color: Color(0xFF9494B8),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered bordered section title used inside the leaderboard pages.
///
/// Optionally shows a [trailing] widget aligned to the right (e.g. an action
/// button such as the Playoff bracket entry). The title text remains visually
/// centered regardless of whether [trailing] is present.
class LeaderboardSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const LeaderboardSectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE000FF), width: 2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(child: trailing!),
            ),
        ],
      ),
    );
  }
}
