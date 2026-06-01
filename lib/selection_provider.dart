import 'package:flutter/material.dart';

class SelectionProvider extends ChangeNotifier {
  int? _selectedLeagueId;
  int? _selectedGameId;

  int? get selectedLeagueId => _selectedLeagueId;
  int? get selectedGameId => _selectedGameId;

  void updateSelection(int leagueId, int gameId) {
    _selectedLeagueId = leagueId;
    _selectedGameId = gameId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedLeagueId = null;
    _selectedGameId = null;
    notifyListeners();
  }
}
