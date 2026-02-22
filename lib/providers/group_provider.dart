import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/api_service.dart';

class GroupProvider extends ChangeNotifier {
  final ApiService _api;
  Group? _currentGroup;
  List<Group> _groups = [];
  bool _loading = false;
  String? _error;

  GroupProvider(this._api);

  Group? get currentGroup => _currentGroup;
  Group? get selectedGroup => _currentGroup;
  List<Group> get groups => _groups;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadUserGroups() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getUserGroups();
      final list = data['groups'] as List<dynamic>?;
      _groups = list?.map((e) => Group.fromJson(e)).toList() ?? [];
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

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
      _groups.insert(0, _currentGroup!);
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
      // Add to list if not already present
      if (!_groups.any((g) => g.id == _currentGroup!.id)) {
        _groups.insert(0, _currentGroup!);
      }
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

  Future<bool> addAdmin(String groupId, String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.addAdmin(groupId, userId);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      await loadGroup(groupId);
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAdmin(String groupId, String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.removeAdmin(groupId, userId);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }
      await loadGroup(groupId);
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
