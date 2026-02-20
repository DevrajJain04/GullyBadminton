import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadUserGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupProv = context.watch<GroupProvider>();
    final authProv = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('My Groups'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProv.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: groupProv.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF)))
          : groupProv.groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_add, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'No groups yet',
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create or join a group to get started',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => groupProv.loadUserGroups(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupProv.groups.length,
                    itemBuilder: (ctx, i) {
                      final group = groupProv.groups[i];
                      final isCreator = authProv.user?.id == group.createdBy;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            groupProv.setGroup(group);
                            Navigator.pushNamed(context, '/group');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCreator
                                    ? [const Color(0xFF0F3460), const Color(0xFF533483)]
                                    : [const Color(0xFF16213E), const Color(0xFF1A1A2E)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCreator
                                    ? const Color(0xFF533483).withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D9FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isCreator ? Icons.shield : Icons.group,
                                    color: const Color(0xFF00D9FF),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (isCreator)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'ADMIN',
                                                style: TextStyle(
                                                  color: Color(0xFF00D9FF),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          Text(
                                            '${group.members.length} member${group.members.length != 1 ? 's' : ''}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.white38),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: const Color(0xFF1A1A2E),
        icon: const Icon(Icons.add),
        label: const Text('Create / Join'),
        onPressed: () => _showCreateJoinSheet(context),
      ),
    );
  }

  void _showCreateJoinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF00D9FF),
                child: Icon(Icons.add, color: Color(0xFF1A1A2E)),
              ),
              title: const Text('Create Group', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Start a new badminton group', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateDialog(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: const Icon(Icons.login, color: Colors.white70),
              ),
              title: const Text('Join Group', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Enter a join code', style: TextStyle(color: Colors.white54)),
              onTap: () {
                Navigator.pop(ctx);
                _showJoinDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Create Group', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Group name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D9FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final nav = Navigator.of(context);
              final groupProv = context.read<GroupProvider>();
              Navigator.pop(ctx);
              final ok = await groupProv.createGroup(nameController.text.trim());
              if (ok && mounted) {
                nav.pushNamed('/group');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Join Group', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: codeController,
          style: const TextStyle(color: Colors.white, letterSpacing: 4),
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Enter code',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D9FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
            onPressed: () async {
              if (codeController.text.trim().isEmpty) return;
              final nav = Navigator.of(context);
              final groupProv = context.read<GroupProvider>();
              Navigator.pop(ctx);
              final ok = await groupProv.joinGroup(codeController.text.trim());
              if (ok && mounted) {
                nav.pushNamed('/group');
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
