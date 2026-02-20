import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart';
import 'providers/player_provider.dart';
import 'providers/match_provider.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/my_groups_screen.dart';
import 'screens/group_dashboard_screen.dart';
import 'screens/live_match_screen.dart';
import 'screens/match_history_screen.dart';
import 'screens/player_list_screen.dart';
import 'screens/add_result_screen.dart';

void main() {
  runApp(const GullyBadmintonApp());
}

class GullyBadmintonApp extends StatelessWidget {
  const GullyBadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    final ws = WebSocketService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider(create: (_) => GroupProvider(api)),
        ChangeNotifierProvider(create: (_) => PlayerProvider(api)),
        ChangeNotifierProvider(create: (_) => MatchProvider(api, ws)),
      ],
      child: MaterialApp(
        title: 'Gully Badminton',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/groups': (_) => const MyGroupsScreen(),
          '/group': (_) => const GroupDashboardScreen(),
          '/live-match': (_) => const LiveMatchScreen(),
          '/match-history': (_) => const MatchHistoryScreen(),
          '/players': (_) => const PlayerListScreen(),
          '/add-result': (_) => const AddResultScreen(),
        },
      ),
    );
  }
}

/// A simple splash that checks for saved session and routes accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.tryAutoLogin();
    if (!mounted) return;

    if (loggedIn) {
      Navigator.of(context).pushReplacementNamed('/groups');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
