import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart';
import 'providers/match_provider.dart';
import 'providers/player_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/create_join_group_screen.dart';
import 'screens/group_dashboard_screen.dart';
import 'screens/live_match_screen.dart';
import 'screens/match_history_screen.dart';
import 'screens/player_list_screen.dart';

void main() {
  runApp(const GullyBadmintonApp());
}

class GullyBadmintonApp extends StatelessWidget {
  const GullyBadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final wsService = WebSocketService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => GroupProvider(apiService)),
        ChangeNotifierProvider(create: (_) => PlayerProvider(apiService)),
        ChangeNotifierProvider(create: (_) => MatchProvider(apiService, wsService)),
      ],
      child: MaterialApp(
        title: 'Gully Badminton',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          primaryColor: const Color(0xFF00D9FF),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D9FF),
            secondary: Color(0xFFE94560),
            surface: Color(0xFF16213E),
          ),
          fontFamily: 'Roboto',
        ),
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/groups': (_) => const CreateJoinGroupScreen(),
          '/dashboard': (_) => const GroupDashboardScreen(),
          '/live': (_) => const LiveMatchScreen(),
          '/history': (_) => const MatchHistoryScreen(),
          '/players': (_) => const PlayerListScreen(),
        },
      ),
    );
  }
}
