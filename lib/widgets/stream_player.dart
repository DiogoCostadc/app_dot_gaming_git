import 'package:flutter/material.dart';
import '../models/match.dart';

class StreamPlayer extends StatefulWidget {
  final Match match;

  const StreamPlayer({
    super.key,
    required this.match,
  });

  @override
  State<StreamPlayer> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  // Extract channel name from full Twitch URL
  String _extractChannelName(String url) {
    if (url.isEmpty) return 'caedrel'; // dummy channel
    
    // Handle different URL formats
    if (url.contains('twitch.tv/')) {
      // https://twitch.tv/gaules -> gaules
      final parts = url.split('twitch.tv/');
      if (parts.length > 1) {
        String channel = parts[1];
        // Remove any trailing slashes or query parameters
        channel = channel.split('/')[0];
        channel = channel.split('?')[0];
        return channel;
      }
    }
    
    // If it's already just a channel name, return as is
    return url;
  }

  @override
  void initState() {
    super.initState();
    debugPrint('=== DEBUG StreamPlayer.initState ===');
    debugPrint('Stream URL: ${widget.match.streamUrl}');
    
    // Extract channel name from URL
    final channelName = _extractChannelName(widget.match.streamUrl);
    debugPrint('Extracted channel: $channelName');
    
    debugPrint('=== END DEBUG StreamPlayer.initState ===');
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Print match status and stream URL
    debugPrint('=== DEBUG StreamPlayer.build ===');
    debugPrint('Match Status: "${widget.match.matchStatus}"');
    debugPrint('Stream URL: "${widget.match.streamUrl}"');
    debugPrint('Is Live: ${widget.match.matchStatus == 'Live'}');
    debugPrint('Has Stream URL: ${widget.match.streamUrl.isNotEmpty}');
    debugPrint('=== END DEBUG StreamPlayer ===');
    
    // Finished matches: show YouTube VOD placeholder (no "AO VIVO" bar).
    if (widget.match.matchStatus == 'Finished') {
      return _buildYoutubeVod();
    }

    return Container(
      color: const Color(0xFF000033),
      child: Column(
        children: [
          // Stream Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red.withValues(alpha: 0.8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AO VIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Stream Placeholder (WebView disabled due to platform issues)
          Expanded(
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.live_tv,
                    color: Color(0xFFFF00FF),
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Twitch Stream',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Channel: ${_extractChannelName(widget.match.streamUrl)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'WebView temporarily disabled',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Platform registration issue',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Open stream in external browser
                      final channelName = _extractChannelName(widget.match.streamUrl);
                      debugPrint('Opening Twitch channel: $channelName');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF00FF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Open in Browser'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder shown for matches with status `Finished`.
  ///
  /// Intended to host a YouTube VOD of the match later. For now it shows a
  /// neutral "replay" panel with no "AO VIVO" indicator.
  Widget _buildYoutubeVod() {
    return Container(
      color: const Color(0xFF000033),
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.smart_display,
                    color: Color(0xFFFF0000),
                    size: 72,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'YouTube Replay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Em breve',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

