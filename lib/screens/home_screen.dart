import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/websocket_provider.dart';
import 'join_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Connect to WebSocket when home screen is opened
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final ws = context.read<WebSocketProvider>();
      
      if (auth.isAuthenticated && auth.token != null && auth.caseId != null) {
        await ws.connect(auth.caseId!, auth.token!);
      }
    });
  }

  @override
  void dispose() {
    context.read<WebSocketProvider>().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();
    final ws = context.watch<WebSocketProvider>();

    if (!auth.isAuthenticated) {
      return const JoinScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const JoinScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pending events: ${sync.pending.length}'),
            if (ws.isConnected)
              Text('WebSocket: Connected', style: TextStyle(color: Colors.green))
            else
              Text('WebSocket: Disconnected', style: TextStyle(color: Colors.red)),
            if (sync.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(sync.error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: sync.isSyncing
                  ? null
                  : () => _addContractionStart(context, auth.caseId!),
              child: const Text('Log contraction start'),
            ),
            ElevatedButton(
              onPressed: sync.isSyncing
                  ? null
                  : () => _addLaborEvent(context, auth.caseId!),
              child: const Text('Log labor event (waters breaking)'),
            ),
            ElevatedButton(
              onPressed: sync.isSyncing
                  ? null
                  : () => _addPostpartumCheckin(context, auth.caseId!),
              child: const Text('Log postpartum check-in'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: sync.isSyncing
                  ? null
                  : () => sync.sync(caseId: auth.caseId!),
              icon: sync.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
          ],
        ),
      ),
    );
  }

  void _addContractionStart(BuildContext context, String caseId) {
    final sync = context.read<SyncProvider>();
    sync.enqueueEvent(
      caseId: caseId,
      type: 'contraction_start',
      payload: {
        'local_seq': DateTime.now().millisecondsSinceEpoch,
      },
      source: 'patient_app',
    );
    // Auto-push immediately
    _pushEvents(context, caseId);
  }

  void _addLaborEvent(BuildContext context, String caseId) {
    final sync = context.read<SyncProvider>();
    sync.enqueueEvent(
      caseId: caseId,
      type: 'labor_event',
      payload: {
        'kind': 'waters_breaking',
        'note': 'Recorded in app',
      },
      source: 'patient_app',
    );
    // Auto-push immediately
    _pushEvents(context, caseId);
  }

  void _addPostpartumCheckin(BuildContext context, String caseId) {
    final sync = context.read<SyncProvider>();
    sync.enqueueEvent(
      caseId: caseId,
      type: 'postpartum_checkin',
      payload: {
        'bleeding': false,
        'fever': false,
        'headache_vision': false,
        'pain': false,
        'note': 'Feeling okay',
      },
      source: 'patient_app',
    );
    // Auto-push immediately
    _pushEvents(context, caseId);
  }

  Future<void> _pushEvents(BuildContext context, String caseId) async {
    final sync = context.read<SyncProvider>();
    await sync.sync(caseId: caseId);
    
    if (context.mounted && sync.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${sync.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
