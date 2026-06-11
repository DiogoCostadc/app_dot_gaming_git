import 'package:flutter/material.dart';
import '../models/playoff.dart';
import '../screens/match_detail_screen.dart';

/// Traditional tournament bracket: all rounds visible at once with connecting
/// lines drawn between paired matches in adjacent rounds.
///
/// The bracket is centered on screen when it fits and becomes scrollable on
/// both axes when it overflows. Empty match slots render as TBD placeholders
/// so the bracket shape is preserved before all matches are scheduled.
class PlayoffBracket extends StatelessWidget {
  final PlayoffSize size;
  final Map<PlayoffStage, List<PlayoffMatch>> matchesByStage;

  const PlayoffBracket({
    super.key,
    required this.size,
    required this.matchesByStage,
  });

  // Layout constants — the connector geometry depends on these being constant
  // across the bracket, so adjust with care.
  static const double _cardHeight = 76;
  static const double _cardWidth = 200;
  static const double _baseGap = 24;
  static const double _connectorWidth = 44;
  static const double _titleHeight = 36;

  /// Stages to render: union of those required by [PlayoffSize] and any with
  /// actual match data. Returned in canonical bracket order (earliest → final).
  List<PlayoffStage> get _displayedStages {
    final required = size.stages.toSet();
    final withData = matchesByStage.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toSet();
    final all = required.union(withData);
    return PlayoffStage.values.where(all.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stages = _displayedStages;
    if (stages.isEmpty) {
      return const Center(
        child: Text(
          'Sem partidas de playoff',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // Force the inner content to occupy at least the viewport so
              // Center actually centers it when it fits, while letting the
              // scroll views take over when it doesn't.
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _BracketBody(
                    stages: stages,
                    matchesByStage: matchesByStage,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The actual bracket layout: a column with stage titles on top and the
/// rounds + connectors row below.
class _BracketBody extends StatelessWidget {
  final List<PlayoffStage> stages;
  final Map<PlayoffStage, List<PlayoffMatch>> matchesByStage;

  const _BracketBody({required this.stages, required this.matchesByStage});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleRow(stages: stages),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < stages.length; i++) ...[
                _RoundColumn(
                  roundIndex: i,
                  stage: stages[i],
                  matches: matchesByStage[stages[i]] ?? const [],
                ),
                if (i < stages.length - 1)
                  _Connector(
                    fromRoundIndex: i,
                    fromMatchCount: stages[i].matchCount,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final List<PlayoffStage> stages;
  const _TitleRow({required this.stages});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          SizedBox(
            width: PlayoffBracket._cardWidth,
            height: PlayoffBracket._titleHeight,
            child: Center(
              child: Text(
                stages[i].label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF00FFFF),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          if (i < stages.length - 1)
            const SizedBox(width: PlayoffBracket._connectorWidth),
        ],
      ],
    );
  }
}

/// One round = vertical column of match cards, with top/bottom padding and
/// inter-card gaps computed so card centers align with the midpoint between
/// the corresponding pair in the previous round.
class _RoundColumn extends StatelessWidget {
  final int roundIndex;
  final PlayoffStage stage;
  final List<PlayoffMatch> matches;

  const _RoundColumn({
    required this.roundIndex,
    required this.stage,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) {
    final cardCount = stage.matchCount;
    final mult = 1 << roundIndex; // 1, 2, 4, 8
    final stride = PlayoffBracket._cardHeight + PlayoffBracket._baseGap;
    final topPad = stride * (mult - 1) / 2;
    final betweenPad = stride * mult - PlayoffBracket._cardHeight;

    // Place each match at the slot index implied by its 1-based MatchNumber.
    // Matches without a MatchNumber fall back to fill remaining slots in
    // their existing (already-sorted) order.
    final slots = List<PlayoffMatch?>.filled(cardCount, null);
    final unplaced = <PlayoffMatch>[];
    for (final m in matches) {
      final n = m.matchNumber;
      if (n != null && n >= 1 && n <= cardCount && slots[n - 1] == null) {
        slots[n - 1] = m;
      } else {
        unplaced.add(m);
      }
    }
    for (final m in unplaced) {
      final empty = slots.indexOf(null);
      if (empty == -1) break;
      slots[empty] = m;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topPad),
        for (int i = 0; i < cardCount; i++) ...[
          if (i > 0) SizedBox(height: betweenPad),
          _MatchCard(match: slots[i]),
        ],
        SizedBox(height: topPad),
      ],
    );
  }
}

/// Draws the connecting lines between two adjacent rounds: pairs of
/// horizontal stubs from each card meet at a vertical join, and a single
/// horizontal line carries the winner toward the next round.
class _Connector extends StatelessWidget {
  final int fromRoundIndex;
  final int fromMatchCount;

  const _Connector({
    required this.fromRoundIndex,
    required this.fromMatchCount,
  });

  @override
  Widget build(BuildContext context) {
    final mult = 1 << fromRoundIndex;
    final stride = PlayoffBracket._cardHeight + PlayoffBracket._baseGap;
    final topPad = stride * (mult - 1) / 2;
    final betweenPad = stride * mult - PlayoffBracket._cardHeight;

    final totalHeight = topPad * 2 +
        PlayoffBracket._cardHeight * fromMatchCount +
        betweenPad * (fromMatchCount > 0 ? fromMatchCount - 1 : 0);

    return SizedBox(
      width: PlayoffBracket._connectorWidth,
      height: totalHeight,
      child: CustomPaint(
        painter: _ConnectorPainter(
          fromMatchCount: fromMatchCount,
          cardHeight: PlayoffBracket._cardHeight,
          topPad: topPad,
          betweenPad: betweenPad,
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final int fromMatchCount;
  final double cardHeight;
  final double topPad;
  final double betweenPad;

  _ConnectorPainter({
    required this.fromMatchCount,
    required this.cardHeight,
    required this.topPad,
    required this.betweenPad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF00FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final stride = cardHeight + betweenPad;

    // Process each pair (2j, 2j+1) → card j in next round.
    final pairs = fromMatchCount ~/ 2;
    for (int j = 0; j < pairs; j++) {
      final i = j * 2;
      final centerY1 = topPad + i * stride + cardHeight / 2;
      final centerY2 = topPad + (i + 1) * stride + cardHeight / 2;
      final midY = (centerY1 + centerY2) / 2;

      // Horizontal stubs from each card to mid X.
      canvas.drawLine(Offset(0, centerY1), Offset(midX, centerY1), paint);
      canvas.drawLine(Offset(0, centerY2), Offset(midX, centerY2), paint);
      // Vertical join.
      canvas.drawLine(Offset(midX, centerY1), Offset(midX, centerY2), paint);
      // Horizontal stub to next round.
      canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
    }

    // If there's an odd leftover card (rare/non-power-of-2), draw a single
    // straight-through line so it's still visually connected.
    if (fromMatchCount.isOdd) {
      final i = fromMatchCount - 1;
      final centerY = topPad + i * stride + cardHeight / 2;
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.fromMatchCount != fromMatchCount ||
      old.cardHeight != cardHeight ||
      old.topPad != topPad ||
      old.betweenPad != betweenPad;
}

class _MatchCard extends StatelessWidget {
  final PlayoffMatch? match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final docId = m?.documentId;
    final tappable = m != null && docId != null && docId.isNotEmpty;

    final card = Container(
      width: PlayoffBracket._cardWidth,
      height: PlayoffBracket._cardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF000033),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF00FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF00FF).withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _TeamRow(
              name: m?.homeTeamName,
              logo: m?.homeTeamLogo,
              score: m?.homeScore,
              isWinner: _isHomeWinner(m),
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xFFFF00FF).withValues(alpha: 0.4),
          ),
          Expanded(
            child: _TeamRow(
              name: m?.awayTeamName,
              logo: m?.awayTeamLogo,
              score: m?.awayScore,
              isWinner: _isAwayWinner(m),
            ),
          ),
        ],
      ),
    );

    if (!tappable) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchDetailScreen(
              documentId: docId,
              isPlayoff: true,
            ),
          ),
        );
      },
      child: card,
    );
  }

  static bool _isHomeWinner(PlayoffMatch? m) {
    if (m?.homeScore == null || m?.awayScore == null) return false;
    return m!.homeScore! > m.awayScore!;
  }

  static bool _isAwayWinner(PlayoffMatch? m) {
    if (m?.homeScore == null || m?.awayScore == null) return false;
    return m!.awayScore! > m.homeScore!;
  }
}

class _TeamRow extends StatelessWidget {
  final String? name;
  final String? logo;
  final int? score;
  final bool isWinner;

  const _TeamRow({
    required this.name,
    required this.logo,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'TBD';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF1A1A4D),
              image: (logo != null && logo!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(logo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: name == null
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            child: Text(
              score?.toString() ?? '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isWinner ? const Color(0xFF00FF66) : Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
