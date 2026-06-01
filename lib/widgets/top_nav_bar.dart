import 'package:flutter/material.dart';

// Top Navigation Bar Widget
class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 76,
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
          // Search Icon (Left side)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Search action
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
                  children: [Icon(Icons.search, color: Colors.white, size: 32)],
                ),
              ),
            ),
          ),
          // Burger Menu Icon (Right side)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Burger menu action
              },
              splashColor: const Color(0xFF00FFFF).withValues(alpha: 0.2),
              highlightColor: const Color(0xFF00FFFF).withValues(alpha: 0.1),
              child: Container(
                width: 60,
                height: double.infinity,
                padding: const EdgeInsets.all(15),
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 6,
                  children: [
                    Container(width: 25, height: 3, color: Colors.white),
                    Container(width: 25, height: 3, color: Colors.white),
                    Container(width: 25, height: 3, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
