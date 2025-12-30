import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/config.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/websocket_provider.dart';
import 'screens/home_screen.dart';
import 'screens/join_screen.dart';
import 'services/api_client.dart';
import 'services/event_queue.dart';
import 'services/secure_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient(baseUrl: Config.baseUrl);
  final storage = SecureStorageService();
  final queue = EventQueue();
  runApp(App(apiClient: apiClient, storage: storage, queue: queue));
}

class App extends StatefulWidget {
  final ApiClient apiClient;
  final SecureStorageService storage;
  final EventQueue queue;

  const App({super.key, required this.apiClient, required this.storage, required this.queue});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthProvider _authProvider;
  late final SyncProvider _syncProvider;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(apiClient: widget.apiClient, storageService: widget.storage);
    _syncProvider = SyncProvider(apiClient: widget.apiClient, queue: widget.queue, storage: widget.storage);
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    await _authProvider.initialize();
    await _syncProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<SyncProvider>.value(value: _syncProvider),
        ChangeNotifierProvider(create: (_) => WebSocketProvider(apiClient: widget.apiClient)),
      ],
      child: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          return MaterialApp(
            title: 'Birth Journal – Patient',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            home: _buildHome(snapshot),
          );
        },
      ),
    );
  }

  Widget _buildHome(AsyncSnapshot<void> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        return const JoinScreen();
      },
    );
  }
}
