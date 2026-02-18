import 'dart:async';
import 'package:flutter/material.dart';
import '../models/match.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class MatchProvider extends ChangeNotifier {
  final ApiService _api;
  final WebSocketService _ws;
  List<Match> _matches = [];
  Match? _currentMatch;
  bool _loading = false;
  String? _error;
  StreamSubscription? _wsSub;

  MatchProvider(this._api, this._ws);

  List<Match> get matches => _matches;
  Match? get currentMatch => _currentMatch;
  bool get loading => _loading;
  String? get error => _error;

  List<Match> get liveMatches =>
      _matches.where((m) => m.status == 'live').toList();

  List<Match> get finishedMatches =>
      _matches.where((m) => m.status == 'finished').toList();

  void connectWebSocket(String groupId) {
    _ws.connect(groupId);
    _wsSub?.cancel();
    _wsSub = _ws.stream.listen((data) {
      final type = data['type'] as String?;
      if (type == 'score_update' || type == 'match_finished' || type == 'match_created') {
        final matchData = data['match'] as Map<String, dynamic>?;
        if (matchData != null) {
          final updatedMatch = Match.fromJson(matchData);
          _updateMatchInList(updatedMatch);
          if (_currentMatch?.id == updatedMatch.id) {
            _currentMatch = updatedMatch;
          }
          notifyListeners();
        }
      }
    });
  }

  void _updateMatchInList(Match updated) {
    final idx = _matches.indexWhere((m) => m.id == updated.id);
    if (idx >= 0) {
      _matches[idx] = updated;
    } else {
      _matches.insert(0, updated);
    }
  }

  void disconnectWebSocket() {
    _wsSub?.cancel();
    _ws.disconnect();
  }

  Future<void> loadMatches(String groupId) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.getMatches(groupId);
      final list = data['matches'] as List<dynamic>?;
      _matches = list?.map((e) => Match.fromJson(e)).toList() ?? [];
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createMatch(
      String groupId, String player1Id, String player2Id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createMatch(groupId, player1Id, player2Id);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      final match = Match.fromJson(data['match']);
      _matches.insert(0, match);
      _currentMatch = match;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void setCurrentMatch(Match match) {
    _currentMatch = match;
    notifyListeners();
  }

  Future<void> updateScore(int player) async {
    if (_currentMatch == null) return;
    try {
      final data = await _api.updateScore(_currentMatch!.id, player);
      if (!data.containsKey('error')) {
        _currentMatch = Match.fromJson(data['match']);
        _updateMatchInList(_currentMatch!);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> undoScore() async {
    if (_currentMatch == null) return;
    try {
      final data = await _api.undoScore(_currentMatch!.id);
      if (!data.containsKey('error')) {
        _currentMatch = Match.fromJson(data['match']);
        _updateMatchInList(_currentMatch!);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> finishMatch() async {
    if (_currentMatch == null) return;
    try {
      final data = await _api.finishMatch(_currentMatch!.id);
      if (!data.containsKey('error')) {
        _currentMatch = Match.fromJson(data['match']);
        _updateMatchInList(_currentMatch!);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}
