import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/api_service.dart';

class PlayerProvider extends ChangeNotifier {
  final ApiService _api;
  List<Player> _players = [];
  bool _loading = false;
  String? _error;

  PlayerProvider(this._api);

  List<Player> get players => _players;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadPlayers(String groupId) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.getPlayers(groupId);
      final list = data['players'] as List<dynamic>?;
      _players = list?.map((e) => Player.fromJson(e)).toList() ?? [];
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> createPlayer(String groupId, String name) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createPlayer(groupId, name);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      final player = Player.fromJson(data['player']);
      _players.add(player);
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

  Future<bool> deletePlayer(String groupId, String playerId) async {
    try {
      final data = await _api.deletePlayer(groupId, playerId);
      if (data.containsKey('error')) return false;
      _players.removeWhere((p) => p.id == playerId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> mergePlayers(
      String groupId, String targetPlayerId, String sourcePlayerId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data =
          await _api.mergePlayers(groupId, targetPlayerId, sourcePlayerId);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      // Remove the source player locally since they've been deleted on backend
      _players.removeWhere((p) => p.id == sourcePlayerId);
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
}
