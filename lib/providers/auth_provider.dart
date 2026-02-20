import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  AuthProvider(this._api);

  User? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;

  /// Try to restore session from SharedPreferences.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    final savedUser = prefs.getString('user_json');
    if (savedToken == null || savedUser == null) return false;

    _token = savedToken;
    _api.setToken(savedToken);
    try {
      _user = User.fromJson(jsonDecode(savedUser));
    } catch (_) {
      // corrupted data — clear and require login
      await prefs.remove('token');
      await prefs.remove('user_json');
      _token = null;
      _api.clearToken();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> register(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(username, password);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      _token = data['token'];
      _user = User.fromJson(data['user']);
      if (_token != null) {
        _api.setToken(_token!);
      }
      await _saveSession();
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

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      _token = data['token'];
      _user = User.fromJson(data['user']);
      _api.setToken(_token!);
      await _saveSession();
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

  Future<void> logout() async {
    _user = null;
    _token = null;
    _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_json');
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('token', _token!);
    if (_user != null) {
      await prefs.setString('user_json', jsonEncode(_user!.toJson()));
    }
  }
}
