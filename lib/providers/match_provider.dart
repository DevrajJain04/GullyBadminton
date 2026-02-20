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
  bool _scoring = false;
  String? _error;
  StreamSubscription? _wsSub;

  MatchProvider(this._api, this._ws);

  List<Match> get matches => _matches;
  Match? get currentMatch => _currentMatch;
  bool get loading => _loading;
  bool get scoring => _scoring;
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
      if (type == 'match_deleted') {
        final deletedId = data['match_id'] as String?;
        if (deletedId != null) {
          _matches.removeWhere((m) => m.id == deletedId);
          if (_currentMatch?.id == deletedId) _currentMatch = null;
          notifyListeners();
        }
      } else if (type == 'score_update' ||
          type == 'match_finished' ||
          type == 'match_created') {
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
      String groupId, List<String> team1Ids, List<String> team2Ids) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createMatch(groupId, team1Ids, team2Ids);
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

  Future<bool> addResult(String groupId, List<String> team1Ids,
      List<String> team2Ids, int score1, int score2) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data =
          await _api.addResult(groupId, team1Ids, team2Ids, score1, score2);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      final match = Match.fromJson(data['match']);
      _matches.insert(0, match);
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

  // Debounced score update — prevents double-taps
  Future<void> updateScore(int team, String playerId) async {
    if (_currentMatch == null || _scoring) return;
    _scoring = true;
    notifyListeners();
    try {
      final data =
          await _api.updateScore(_currentMatch!.id, team, playerId);
      if (!data.containsKey('error')) {
        _currentMatch = Match.fromJson(data['match']);
        _updateMatchInList(_currentMatch!);
      }
    } catch (e) {
      _error = e.toString();
    }
    _scoring = false;
    notifyListeners();
  }

  Future<void> undoScore() async {
    if (_currentMatch == null || _scoring) return;
    _scoring = true;
    notifyListeners();
    try {
      final data = await _api.undoScore(_currentMatch!.id);
      if (!data.containsKey('error')) {
        _currentMatch = Match.fromJson(data['match']);
        _updateMatchInList(_currentMatch!);
      }
    } catch (e) {
      _error = e.toString();
    }
    _scoring = false;
    notifyListeners();
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

  Future<bool> deleteMatch(String matchId) async {
    try {
      final data = await _api.deleteMatch(matchId);
      if (data.containsKey('error')) return false;
      _matches.removeWhere((m) => m.id == matchId);
      if (_currentMatch?.id == matchId) _currentMatch = null;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editScore(String matchId, int score1, int score2) async {
    try {
      final data = await _api.editScore(matchId, score1, score2);
      if (data.containsKey('error')) return false;
      final updated = Match.fromJson(data['match']);
      _updateMatchInList(updated);
      if (_currentMatch?.id == matchId) _currentMatch = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}
