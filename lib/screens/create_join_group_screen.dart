import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';

class CreateJoinGroupScreen extends StatefulWidget {
  const CreateJoinGroupScreen({super.key});

  @override
  State<CreateJoinGroupScreen> createState() => _CreateJoinGroupScreenState();
}

class _CreateJoinGroupScreenState extends State<CreateJoinGroupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupProv = context.watch<GroupProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF00D9FF),
          labelColor: const Color(0xFF00D9FF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Create Group'),
            Tab(text: 'Join Group'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Create Tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_add, size: 60, color: Color(0xFF00D9FF)),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Group Name', Icons.group),
                ),
                if (groupProv.error != null) ...[
                  const SizedBox(height: 12),
                  Text(groupProv.error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: groupProv.loading ? null : _createGroup,
                    child: groupProv.loading
                        ? const CircularProgressIndicator()
                        : const Text('Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          // Join Tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link, size: 60, color: Color(0xFF00D9FF)),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration('Join Code', Icons.vpn_key),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: groupProv.loading ? null : _joinGroup,
                    child: groupProv.loading
                        ? const CircularProgressIndicator()
                        : const Text('Join', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: const Color(0xFF00D9FF)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00D9FF)),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
    );
  }

  void _createGroup() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final success = await context.read<GroupProvider>().createGroup(_nameCtrl.text.trim());
    if (success && mounted) {
      final group = context.read<GroupProvider>().currentGroup!;
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Text('Group Created!', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this join code:', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                SelectableText(
                  group.joinCode,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00D9FF)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text('Go to Dashboard', style: TextStyle(color: Color(0xFF00D9FF))),
              ),
            ],
          ),
        );
      }
    }
  }

  void _joinGroup() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    final success = await context.read<GroupProvider>().joinGroup(_codeCtrl.text.trim());
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}
