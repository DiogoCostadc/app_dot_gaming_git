import 'package:flutter/material.dart';

/// A compact page indicator that adapts to any page count:
///
/// - **1 page** → indicator is hidden entirely.
/// - **2 pages** → 2 dots, one per page.
/// - **3+ pages** → always exactly 3 dots representing
///   *first / middle / last*. The middle dot is highlighted for any
///   middle page (anything that isn't the first or last) and pulses
///   each time the current page changes, so the user perceives motion
///   while swiping through middle pages without the dot count growing.
///
/// Tapping the dots navigates: first dot → page 0, last dot → last page,
/// middle dot → an interior page (the geometric middle).
class PageDotsIndicator extends StatelessWidget {
  /// Total number of pages in the parent PageView / TabBarView.
  final int pageCount;

  /// 0-based index of the currently visible page.
  final int currentPage;

  /// Called when the user taps one of the dots. The argument is the
  /// page index to navigate to.
  final ValueChanged<int>? onDotTap;

  /// Foreground colour used for the active dot and the focused glow.
  /// Defaults to the app's neon cyan.
  final Color activeColor;

  const PageDotsIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.onDotTap,
    this.activeColor = const Color(0xFF00FFFF),
  });

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();

    if (pageCount == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Dot(
            active: currentPage == 0,
            color: activeColor,
            onTap: onDotTap == null ? null : () => onDotTap!(0),
          ),
          const SizedBox(width: 12),
          _Dot(
            active: currentPage == 1,
            color: activeColor,
            onTap: onDotTap == null ? null : () => onDotTap!(1),
          ),
        ],
      );
    }

    // 3+ pages: always three dots — first / middle / last.
    final last = pageCount - 1;
    final clamped = currentPage.clamp(0, last);
    final isFirst = clamped == 0;
    final isLast = clamped == last;
    final isMiddle = !isFirst && !isLast;
    final middleTarget = pageCount ~/ 2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(
          active: isFirst,
          color: activeColor,
          onTap: onDotTap == null ? null : () => onDotTap!(0),
        ),
        const SizedBox(width: 12),
        _Dot(
          active: isMiddle,
          color: activeColor,
          // When the middle dot is active, the pulseKey changes every time
          // the current page changes, retriggering the scale animation so
          // the dot "ticks" as the user swipes through middle pages.
          pulseKey: isMiddle ? ValueKey(clamped) : null,
          onTap: onDotTap == null ? null : () => onDotTap!(middleTarget),
        ),
        const SizedBox(width: 12),
        _Dot(
          active: isLast,
          color: activeColor,
          onTap: onDotTap == null ? null : () => onDotTap!(last),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final Color color;
  final VoidCallback? onTap;
  final Key? pulseKey;

  const _Dot({
    required this.active,
    required this.color,
    this.onTap,
    this.pulseKey,
  });

  @override
  Widget build(BuildContext context) {
    final core = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: active ? 16 : 12,
      height: active ? 16 : 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : color.withValues(alpha: 0.4),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );

    // Pulse the middle dot whenever the page index inside the middle range
    // changes, giving subtle visual feedback during swipes.
    final body = pulseKey != null
        ? TweenAnimationBuilder<double>(
            key: pulseKey,
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: core,
          )
        : core;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.4),
          child: body,
        ),
      ),
    );
  }
}
