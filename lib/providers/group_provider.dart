import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';

class GroupProvider extends ChangeNotifier {
  final ApiService _api;
  Group? _currentGroup;
  bool _loading = false;
  String? _error;

  GroupProvider(this._api);

  Group? get currentGroup => _currentGroup;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> createGroup(String name) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createGroup(name);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      _currentGroup = Group.fromJson(data['group']);
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

  Future<bool> joinGroup(String code) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.joinGroup(code);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      _currentGroup = Group.fromJson(data['group']);
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

  Future<void> loadGroup(String id) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.getGroup(id);
      _currentGroup = Group.fromJson(data['group']);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void setGroup(Group group) {
    _currentGroup = group;
    notifyListeners();
  }
}
