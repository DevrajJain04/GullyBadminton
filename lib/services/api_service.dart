import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ---------- Auth ----------

  Future<Map<String, dynamic>> register(String username, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ---------- Groups ----------

  Future<Map<String, dynamic>> getUserGroups() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user/groups'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createGroup(String name) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groups'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> joinGroup(String code) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groups/join'),
      headers: _headers,
      body: jsonEncode({'code': code}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getGroup(String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/groups/$id'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  // ---------- Players ----------

  Future<Map<String, dynamic>> createPlayer(String groupId, String name) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/players'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getPlayers(String groupId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/players'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> deletePlayer(String groupId, String playerId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/players/$playerId'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> mergePlayers(
      String groupId, String targetPlayerId, String sourcePlayerId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/players/merge'),
      headers: _headers,
      body: jsonEncode({
        'target_player_id': targetPlayerId,
        'source_player_id': sourcePlayerId,
      }),
    );
    return jsonDecode(res.body);
  }

  // ---------- Matches ----------

  Future<Map<String, dynamic>> createMatch(
      String groupId, List<String> team1Ids, List<String> team2Ids) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matches'),
      headers: _headers,
      body: jsonEncode({
        'group_id': groupId,
        'team1_ids': team1Ids,
        'team2_ids': team2Ids,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> addResult(String groupId, List<String> team1Ids,
      List<String> team2Ids, int score1, int score2) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matches/result'),
      headers: _headers,
      body: jsonEncode({
        'group_id': groupId,
        'team1_ids': team1Ids,
        'team2_ids': team2Ids,
        'score1': score1,
        'score2': score2,
      }),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getMatches(String groupId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/matches'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateScore(
      String matchId, int team, String playerId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matches/$matchId/score'),
      headers: _headers,
      body: jsonEncode({'team': team, 'player_id': playerId}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> editScore(String matchId, int score1, int score2) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/matches/$matchId/score'),
      headers: _headers,
      body: jsonEncode({'score1': score1, 'score2': score2}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> undoScore(String matchId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matches/$matchId/undo'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> finishMatch(String matchId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matches/$matchId/finish'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> deleteMatch(String matchId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/matches/$matchId'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }
}
