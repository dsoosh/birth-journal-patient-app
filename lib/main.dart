import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/config.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/websocket_provider.dart';
import 'screens/home_screen.dart';
import 'screens/join_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'services/api_client.dart';
import 'services/event_queue.dart';
import 'services/secure_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient(baseUrl: Config.apiUrl);
  final storage = SecureStorageService();
  final queue = EventQueue();
  runApp(App(apiClient: apiClient, storage: storage, queue: queue));
}

class App extends StatefulWidget {
  final ApiClient apiClient;
  final SecureStorageService storage;
  final EventQueue queue;

  const App({
    super.key,
    required this.apiClient,
    required this.storage,
    required this.queue,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final AuthProvider _authProvider;
  late final SyncProvider _syncProvider;
  late final LanguageProvider _languageProvider;
  late final Future<void> _initFuture;

  // App state
  bool _hasPin = false;
  bool _pinVerified = false;
  DateTime? _lastPaused;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authProvider = AuthProvider(
      apiClient: widget.apiClient,
      storageService: widget.storage,
    );
    _syncProvider = SyncProvider(
      apiClient: widget.apiClient,
      queue: widget.queue,
      storage: widget.storage,
    );
    _languageProvider = LanguageProvider();
    _initFuture = _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPaused = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // If app was paused for more than 5 minutes, require PIN again
      if (_lastPaused != null) {
        final elapsed = DateTime.now().difference(_lastPaused!);
        if (elapsed.inMinutes >= 5) {
          setState(() => _pinVerified = false);
        }
      }
    }
  }

  Future<void> _initialize() async {
    await _authProvider.initialize();
    await _syncProvider.initialize();

    // Check if PIN is set up
    _hasPin = await widget.storage.hasPin();

    // Check if session is still valid
    final sessionValidUntil = await widget.storage.getSessionValidUntil();
    if (sessionValidUntil != null &&
        sessionValidUntil.isAfter(DateTime.now())) {
      _pinVerified = true;
    }
  }

  void _onPinSet() {
    setState(() {
      _hasPin = true;
      _pinVerified = true;
    });
  }

  void _onPinVerified() {
    setState(() => _pinVerified = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<SyncProvider>.value(value: _syncProvider),
        ChangeNotifierProvider<LanguageProvider>.value(
          value: _languageProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => WebSocketProvider(apiClient: widget.apiClient),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              return MaterialApp(
                title: 'Birth Journal – Patient',
                locale: langProvider.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en'), Locale('pl')],
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
                  useMaterial3: true,
                ),
                home: _buildHome(snapshot),
              );
            },
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
        // Flow:
        // 1. Not authenticated & not claimed -> JoinScreen (pair with midwife)
        // 2. Authenticated & claimed but no PIN -> PinSetupScreen
        // 3. Has PIN but session expired -> PinEntryScreen
        // 4. Everything OK -> HomeScreen

        if (!auth.isAuthenticated || !auth.claimed) {
          // Need to pair with midwife first
          return const JoinScreen();
        }

        if (!_hasPin) {
          // Need to set up PIN after pairing
          return PinSetupScreen(storage: widget.storage, onPinSet: _onPinSet);
        }

        if (!_pinVerified) {
          // Need to enter PIN
          return PinEntryScreen(
            storage: widget.storage,
            onPinVerified: _onPinVerified,
          );
        }

        // All good, show home
        return const HomeScreen();
      },
    );
  }
}
