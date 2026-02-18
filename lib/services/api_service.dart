import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  String? _token;

  void setToken(String token) {
    _token = token;
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

  // ---------- Matches ----------

  Future<Map<String, dynamic>> createMatch(
      String groupId, String player1Id, String player2Id) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matches'),
      headers: _headers,
      body: jsonEncode({
        'group_id': groupId,
        'player1_id': player1Id,
        'player2_id': player2Id,
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

  Future<Map<String, dynamic>> updateScore(String matchId, int player) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/matches/$matchId/score'),
      headers: _headers,
      body: jsonEncode({'player': player}),
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
}
