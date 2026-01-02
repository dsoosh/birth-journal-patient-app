import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/events_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/websocket_provider.dart';
import 'join_screen.dart';

// Re-export MidwifeFeedback for use in widget
export '../providers/events_provider.dart' show MidwifeFeedback;

class _SymptomButton {
  final IconData icon;
  final String label;
  final Color color;
  final String kind;
  final String severity;

  _SymptomButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.kind,
    required this.severity,
  });
}

class _Contraction {
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;

  _Contraction({required this.startTime, this.endTime, this.durationSeconds});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Contraction tracking state
  bool _isContracting = false;
  DateTime? _contractionStartTime;
  Timer? _contractionTimer;
  int _contractionSeconds = 0;

  // Timeline timeframe
  int _selectedHours = 8;

  // List of recorded contractions
  final List<_Contraction> _contractions = [];

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket and fetch events when home screen is opened
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final ws = context.read<WebSocketProvider>();
      final events = context.read<EventsProvider>();

      if (auth.isAuthenticated && auth.token != null && auth.caseId != null) {
        // Set up callback to add new events from WebSocket
        ws.onNewEvent = (event) {
          events.addEvent(event);
        };
        
        await ws.connect(auth.caseId!, auth.token!);
        // Fetch existing events to show feedback
        await events.fetchEvents(auth.caseId!);
      }
    });
  }

  @override
  void dispose() {
    _contractionTimer?.cancel();
    context.read<WebSocketProvider>().disconnect();
    super.dispose();
  }

  void _startContraction(String caseId) {
    setState(() {
      _isContracting = true;
      _contractionStartTime = DateTime.now();
      _contractionSeconds = 0;
    });

    // Start timer
    _contractionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _contractionSeconds++;
      });
    });

    // Send event
    final sync = context.read<SyncProvider>();
    sync.enqueueEvent(
      caseId: caseId,
      type: 'contraction_start',
      payload: {'local_seq': DateTime.now().millisecondsSinceEpoch},
      source: 'patient_app',
    );
    _pushEvents(context, caseId);
  }

  void _stopContraction(String caseId) {
    _contractionTimer?.cancel();

    final duration = _contractionSeconds;
    final startTime = _contractionStartTime!;

    setState(() {
      _isContracting = false;
      _contractions.insert(
        0,
        _Contraction(
          startTime: startTime,
          endTime: DateTime.now(),
          durationSeconds: duration,
        ),
      );
      _contractionStartTime = null;
      _contractionSeconds = 0;
    });

    // Send event
    final sync = context.read<SyncProvider>();
    sync.enqueueEvent(
      caseId: caseId,
      type: 'contraction_end',
      payload: {'duration_s': duration},
      source: 'patient_app',
    );
    _pushEvents(context, caseId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contraction recorded: ${duration}s'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();
    final ws = context.watch<WebSocketProvider>();

    if (!auth.isAuthenticated) {
      return const JoinScreen();
    }

    // Disable UI if case is closed
    final isClosed = auth.isClosed;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Case switcher (shows when multiple cases exist)
          if (auth.cases.length > 1 || auth.cases.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Switch case',
              onSelected: (value) async {
                if (value == 'add_new') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JoinScreen(isAddingCase: true)),
                  );
                } else {
                  await auth.switchToCase(value);
                  // Reconnect WebSocket for new case
                  final wsProvider = context.read<WebSocketProvider>();
                  final eventsProvider = context.read<EventsProvider>();
                  wsProvider.disconnect();
                  if (auth.token != null && auth.caseId != null) {
                    wsProvider.onNewEvent = (event) {
                      eventsProvider.addEvent(event);
                    };
                    await wsProvider.connect(auth.caseId!, auth.token!);
                    await eventsProvider.fetchEvents(auth.caseId!);
                  }
                }
              },
              itemBuilder: (context) => [
                ...auth.cases.map((caseInfo) => PopupMenuItem<String>(
                  value: caseInfo.caseId,
                  child: Row(
                    children: [
                      Icon(
                        caseInfo.caseId == auth.caseId
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 18,
                        color: caseInfo.isClosed
                            ? Colors.grey
                            : (caseInfo.caseId == auth.caseId
                                ? Colors.green
                                : Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Case ${caseInfo.shortId}...',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: caseInfo.isClosed ? Colors.grey : null,
                          decoration: caseInfo.isClosed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (caseInfo.isClosed) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock, size: 14, color: Colors.grey),
                      ],
                    ],
                  ),
                )),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'add_new',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Add new case'),
                    ],
                  ),
                ),
              ],
            ),
          // Language selector
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language),
            onSelected: (lang) {
              context.read<LanguageProvider>().setLanguage(lang);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AppLanguage.en,
                child: Text('🇬🇧 English'),
              ),
              const PopupMenuItem(
                value: AppLanguage.pl,
                child: Text('🇵🇱 Polski'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: isClosed
          ? _buildClosedCaseBody(context, auth)
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Case ID and status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ws.isConnected ? Icons.cloud_done : Icons.cloud_off,
                            color: ws.isConnected
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ws.isConnected ? 'Connected' : 'Offline',
                            style: TextStyle(
                              color: ws.isConnected
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (sync.pending.isNotEmpty)
                            Chip(
                              label: Text('${sync.pending.length} pending'),
                              backgroundColor: Colors.orange.shade100,
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Case: ${auth.caseId?.substring(0, 8) ?? 'Unknown'}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (sync.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        sync.error!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Contraction Timer Button - only show in labor mode
              if (!auth.postpartumActive) ...[
                _buildContractionButton(auth.caseId!, sync.isSyncing),

                const SizedBox(height: 16),

                // Contractions Timeline
                if (_contractions.isNotEmpty) ...[
                  _buildContractionsTimeline(),
                  const SizedBox(height: 16),
                ],
              ],

              const Divider(),
              const SizedBox(height: 16),

              // Section title - changes based on mode
              Row(
                children: [
                  Expanded(
                    child: Text(
                      auth.postpartumActive
                          ? AppLocalizations.of(
                              context,
                            ).reportPostpartumSymptoms
                          : AppLocalizations.of(
                              context,
                            ).reportSymptomsToMidwife,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (auth.postpartumActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.child_friendly,
                            size: 14,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context).postpartumMode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (auth.laborActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pregnant_woman,
                            size: 14,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context).laborMode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Symptom buttons in 2 columns
              _buildSymptomGrid(context, auth.caseId!, sync.isSyncing),

              const SizedBox(height: 24),

              // Midwife Feedback Section
              _buildMidwifeFeedbackSection(context),

              const SizedBox(height: 24),

              // Midwife Notes Section
              _buildMidwifeNotesSection(context),

              const SizedBox(height: 24),

              // Sync button
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClosedCaseBody(BuildContext context, AuthProvider auth) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Case Closed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This case has been closed by your midwife. Thank you for using Birth Journal!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Case: ${auth.caseId?.substring(0, 8) ?? "Unknown"}...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'monospace',
                ),
              ),
              if (auth.cases.length > 1) ...[
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () async {
                    // Find another open case
                    final openCase = auth.cases.firstWhere(
                      (c) => !c.isClosed && c.caseId != auth.caseId,
                      orElse: () => auth.cases.first,
                    );
                    if (!openCase.isClosed) {
                      await auth.switchToCase(openCase.caseId);
                    }
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch to another case'),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JoinScreen(isAddingCase: true),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add new case'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractionButton(String caseId, bool isSyncing) {
    return Card(
      elevation: 4,
      color: _isContracting ? Colors.red.shade50 : Colors.purple.shade50,
      child: InkWell(
        onTap: isSyncing
            ? null
            : () {
                if (_isContracting) {
                  _stopContraction(caseId);
                } else {
                  _startContraction(caseId);
                }
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            children: [
              Icon(
                _isContracting ? Icons.stop_circle : Icons.play_circle,
                size: 64,
                color: _isContracting ? Colors.red : Colors.purple,
              ),
              const SizedBox(height: 12),
              Text(
                _isContracting ? 'STOP CONTRACTION' : 'START CONTRACTION',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isContracting
                      ? Colors.red.shade900
                      : Colors.purple.shade900,
                ),
              ),
              if (_isContracting) ...[
                const SizedBox(height: 12),
                Text(
                  '${_contractionSeconds}s',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractionsTimeline() {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final selectedPeriod = now.subtract(Duration(hours: _selectedHours));
    final recentContractions = _contractions
        .where((c) => c.startTime.isAfter(selectedPeriod))
        .toList();
    final recentCount = recentContractions.length;

    // Calculate vital stats
    final vitalStats = _calculateVitalStats(recentContractions);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  l10n.contractions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: recentCount > 12
                        ? Colors.orange.shade100
                        : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    l10n.inLastHours(_selectedHours),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: recentCount > 12
                          ? Colors.orange.shade900
                          : Colors.purple.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Timeframe selector
            _TimeframeSelector(
              selectedHours: _selectedHours,
              onChanged: (hours) => setState(() => _selectedHours = hours),
            ),
            const SizedBox(height: 16),

            // Timeline Graph
            if (recentContractions.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: CustomPaint(
                  size: const Size(double.infinity, 80),
                  painter: _ContractionsGraphPainter(
                    contractions: recentContractions,
                    timeWindowHours: _selectedHours,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Time axis labels
              _TimeAxisLabels(hours: _selectedHours),
              const SizedBox(height: 16),

              // Vital Stats
              _VitalStatsRow(
                stats: vitalStats,
                periodLabel: '${_selectedHours}h',
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    l10n.startContractionToSeeTimeline,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _VitalStats _calculateVitalStats(List<_Contraction> contractions) {
    if (contractions.isEmpty) {
      return _VitalStats(
        avgDuration: 0,
        avgGapMinutes: 0,
        count: 0,
        durationTrend: 0,
        gapTrend: 0,
      );
    }

    // Sort by start time (oldest first) for calculations
    final sorted = List<_Contraction>.from(contractions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Calculate averages
    int totalDuration = 0;
    int countWithDuration = 0;
    for (final c in sorted) {
      if (c.durationSeconds != null) {
        totalDuration += c.durationSeconds!;
        countWithDuration++;
      }
    }
    final avgDuration = countWithDuration > 0
        ? totalDuration ~/ countWithDuration
        : 0;

    // Calculate gaps between contractions
    final gaps = <int>[];
    for (int i = 1; i < sorted.length; i++) {
      final prevEnd = sorted[i - 1].endTime ?? sorted[i - 1].startTime;
      final gap = sorted[i].startTime.difference(prevEnd).inSeconds;
      if (gap > 0) gaps.add(gap);
    }
    final avgGapSeconds = gaps.isEmpty
        ? 0
        : gaps.fold<int>(0, (sum, g) => sum + g) ~/ gaps.length;
    final avgGapMinutes = (avgGapSeconds / 60).round();

    // Calculate trends (compare first half vs second half)
    double durationTrend = 0;
    double gapTrend = 0;

    if (sorted.length >= 4) {
      final midpoint = sorted.length ~/ 2;
      final firstHalf = sorted.sublist(0, midpoint);
      final secondHalf = sorted.sublist(midpoint);

      int firstHalfTotal = 0;
      int firstHalfCount = 0;
      for (final c in firstHalf) {
        if (c.durationSeconds != null) {
          firstHalfTotal += c.durationSeconds!;
          firstHalfCount++;
        }
      }
      int secondHalfTotal = 0;
      int secondHalfCount = 0;
      for (final c in secondHalf) {
        if (c.durationSeconds != null) {
          secondHalfTotal += c.durationSeconds!;
          secondHalfCount++;
        }
      }

      if (firstHalfCount > 0 && secondHalfCount > 0) {
        final firstHalfAvgDuration = firstHalfTotal / firstHalfCount;
        final secondHalfAvgDuration = secondHalfTotal / secondHalfCount;
        durationTrend = secondHalfAvgDuration - firstHalfAvgDuration;
      }

      // Gap trends
      final firstHalfGaps = <int>[];
      for (int i = 1; i < firstHalf.length; i++) {
        final prevEnd = firstHalf[i - 1].endTime ?? firstHalf[i - 1].startTime;
        firstHalfGaps.add(firstHalf[i].startTime.difference(prevEnd).inSeconds);
      }
      final secondHalfGaps = <int>[];
      for (int i = 1; i < secondHalf.length; i++) {
        final prevEnd =
            secondHalf[i - 1].endTime ?? secondHalf[i - 1].startTime;
        secondHalfGaps.add(
          secondHalf[i].startTime.difference(prevEnd).inSeconds,
        );
      }

      if (firstHalfGaps.isNotEmpty && secondHalfGaps.isNotEmpty) {
        final firstHalfAvgGap =
            firstHalfGaps.fold<int>(0, (sum, g) => sum + g) /
            firstHalfGaps.length;
        final secondHalfAvgGap =
            secondHalfGaps.fold<int>(0, (sum, g) => sum + g) /
            secondHalfGaps.length;
        gapTrend = secondHalfAvgGap - firstHalfAvgGap;
      }
    }

    return _VitalStats(
      avgDuration: avgDuration,
      avgGapMinutes: avgGapMinutes,
      count: contractions.length,
      durationTrend: durationTrend,
      gapTrend: gapTrend,
    );
  }

  Widget _buildSymptomGrid(
    BuildContext context,
    String caseId,
    bool isSyncing,
  ) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);

    // Choose symptoms based on current mode
    final symptoms = auth.postpartumActive
        ? _getPostpartumSymptoms(l10n)
        : _getLaborSymptoms(l10n);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: symptoms.length,
      itemBuilder: (context, index) {
        final symptom = symptoms[index];
        return _buildSymptomCard(context, caseId, symptom, isSyncing);
      },
    );
  }

  List<_SymptomButton> _getLaborSymptoms(AppLocalizations l10n) {
    return [
      _SymptomButton(
        icon: Icons.water_drop,
        label: l10n.watersBreaking,
        color: Colors.blue,
        kind: 'waters_breaking',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.opacity,
        label: l10n.mucusPlug,
        color: Colors.amber,
        kind: 'mucus_plug',
        severity: 'medium',
      ),
      _SymptomButton(
        icon: Icons.bloodtype,
        label: l10n.bleeding,
        color: Colors.red,
        kind: 'bleeding',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.child_care,
        label: l10n.reducedMovement,
        color: Colors.orange,
        kind: 'reduced_fetal_movement',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.arrow_downward,
        label: l10n.bellyLowering,
        color: Colors.green,
        kind: 'belly_lowering',
        severity: 'low',
      ),
      _SymptomButton(
        icon: Icons.sick,
        label: l10n.nausea,
        color: Colors.lightGreen,
        kind: 'nausea',
        severity: 'low',
      ),
      _SymptomButton(
        icon: Icons.visibility_off,
        label: l10n.visionIssues,
        color: Colors.deepOrange,
        kind: 'headache_vision',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.thermostat,
        label: l10n.feverChills,
        color: Colors.deepPurple,
        kind: 'fever_chills',
        severity: 'high',
      ),
    ];
  }

  List<_SymptomButton> _getPostpartumSymptoms(AppLocalizations l10n) {
    return [
      _SymptomButton(
        icon: Icons.bloodtype,
        label: l10n.heavyBleeding,
        color: Colors.red,
        kind: 'postpartum_bleeding',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.child_care,
        label: l10n.breastfeedingIssues,
        color: Colors.pink,
        kind: 'breastfeeding_issues',
        severity: 'medium',
      ),
      _SymptomButton(
        icon: Icons.mood_bad,
        label: l10n.moodChanges,
        color: Colors.purple,
        kind: 'mood_changes',
        severity: 'medium',
      ),
      _SymptomButton(
        icon: Icons.thermostat,
        label: l10n.feverChills,
        color: Colors.deepOrange,
        kind: 'fever_chills',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.healing,
        label: l10n.woundPain,
        color: Colors.amber,
        kind: 'wound_pain',
        severity: 'medium',
      ),
      _SymptomButton(
        icon: Icons.visibility_off,
        label: l10n.visionIssues,
        color: Colors.indigo,
        kind: 'headache_vision',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.directions_walk,
        label: l10n.legPainSwelling,
        color: Colors.teal,
        kind: 'leg_pain_swelling',
        severity: 'high',
      ),
      _SymptomButton(
        icon: Icons.local_hospital,
        label: l10n.urinationIssues,
        color: Colors.blue,
        kind: 'urination_issues',
        severity: 'medium',
      ),
    ];
  }

  Widget _buildSymptomCard(
    BuildContext context,
    String caseId,
    _SymptomButton symptom,
    bool isSyncing,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isSyncing
            ? null
            : () => _reportSymptom(
                context,
                caseId,
                symptom.kind,
                symptom.severity,
              ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(symptom.icon, color: symptom.color, size: 32),
              const SizedBox(height: 8),
              Text(
                symptom.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportSymptom(
    BuildContext context,
    String caseId,
    String kind,
    String severity,
  ) {
    final sync = context.read<SyncProvider>();
    sync.enqueueEvent(
      caseId: caseId,
      type: 'labor_event',
      payload: {'kind': kind, 'severity': severity, 'note': 'Reported via app'},
      source: 'patient_app',
    );

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Symptom reported to midwife'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Auto-sync
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

    // Refresh events to get latest feedback
    if (context.mounted) {
      final events = context.read<EventsProvider>();
      await events.fetchEvents(caseId);
    }
  }

  Widget _buildMidwifeFeedbackSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final events = context.watch<EventsProvider>();
    final feedback = events.feedbackItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.feedback, size: 20, color: Colors.indigo),
            const SizedBox(width: 8),
            Text(
              l10n.midwifeFeedback,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (events.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (feedback.isEmpty)
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.noFeedbackYet,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...feedback.take(5).map((item) => _buildFeedbackCard(context, item)),
      ],
    );
  }

  Widget _buildFeedbackCard(BuildContext context, MidwifeFeedback feedback) {
    final l10n = AppLocalizations.of(context);
    final dateFormatter = DateFormat('MMM d, HH:mm');

    // Determine status
    final bool isResolved = feedback.resolved;
    final bool isAcknowledged = feedback.acknowledged;
    final bool hasReaction = feedback.reaction != null;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isResolved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = l10n.resolved;
    } else if (hasReaction) {
      statusColor = Colors.blue;
      statusIcon = Icons.thumb_up;
      statusText = _getReactionLabel(feedback.reaction);
    } else if (isAcknowledged) {
      statusColor = Colors.blue;
      statusIcon = Icons.visibility;
      statusText = l10n.acknowledged;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = l10n.pendingReview;
    }

    // Get readable symptom name
    final symptomName = _getSymptomDisplayName(context, feedback.originalKind);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    symptomName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  dateFormatter.format(feedback.originalTs),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (feedback.reactionAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.thumb_up, size: 14, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(feedback.reactionAt!),
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                ] else if (feedback.resolvedAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.done_all, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(feedback.resolvedAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                ] else if (feedback.acknowledgedAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.done, size: 14, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatter.format(feedback.acknowledgedAt!),
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                ],
              ],
            ),
            if (hasReaction) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _getReactionEmoji(feedback.reaction),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getReactionMessage(feedback.reaction, l10n),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isAcknowledged && !isResolved) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.yourReportSeen,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isResolved) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.midwifeResolved,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSymptomDisplayName(BuildContext context, String? kind) {
    if (kind == null) return 'Unknown symptom';
    final l10n = AppLocalizations.of(context);

    switch (kind) {
      case 'waters_breaking':
        return l10n.watersBreaking;
      case 'mucus_plug':
        return l10n.mucusPlug;
      case 'bleeding':
        return l10n.bleeding;
      case 'reduced_fetal_movement':
        return l10n.reducedMovement;
      case 'belly_lowering':
        return l10n.bellyLowering;
      case 'nausea':
        return l10n.nausea;
      case 'headache_vision':
        return l10n.visionIssues;
      case 'fever_chills':
        return l10n.feverChills;
      case 'postpartum_bleeding':
        return l10n.heavyBleeding;
      case 'breastfeeding_issues':
        return l10n.breastfeedingIssues;
      case 'mood_changes':
        return l10n.moodChanges;
      case 'wound_pain':
        return l10n.woundPain;
      case 'leg_pain_swelling':
        return l10n.legPainSwelling;
      case 'urination_issues':
        return l10n.urinationIssues;
      case 'HEAVY_BLEEDING':
        return l10n.heavyBleeding;
      default:
        return kind.replaceAll('_', ' ');
    }
  }

  String _getReactionLabel(String? reaction) {
    switch (reaction) {
      case 'ack':
        return 'Acknowledged';
      case 'coming':
        return "I'm coming";
      case 'ok':
        return "It's OK";
      case 'seen':
        return 'Seen';
      default:
        return 'Acknowledged';
    }
  }

  String _getReactionEmoji(String? reaction) {
    switch (reaction) {
      case 'ack':
        return '✓';
      case 'coming':
        return '🚗';
      case 'ok':
        return '👍';
      case 'seen':
        return '👁';
      default:
        return '✓';
    }
  }

  String _getReactionMessage(String? reaction, AppLocalizations l10n) {
    switch (reaction) {
      case 'ack':
        return 'Midwife acknowledged your report';
      case 'coming':
        return 'Midwife is on the way';
      case 'ok':
        return 'Midwife says it\'s okay';
      case 'seen':
        return 'Midwife has reviewed';
      default:
        return 'Midwife responded';
    }
  }

  Widget _buildMidwifeNotesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final events = context.watch<EventsProvider>();
    final notes = events.midwifeNotes;
    final dateFormatter = DateFormat('MMM d, HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.note, size: 20, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              l10n.midwifeNotes,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.noNotesYet,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...notes
              .take(5)
              .map(
                (note) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.teal.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.fromMidwife,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateFormatter.format(DateTime.parse(note.ts)),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.teal.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.payload['text']?.toString() ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

// Vital stats data class
class _VitalStats {
  final int avgDuration;
  final int avgGapMinutes;
  final int count;
  final double durationTrend;
  final double gapTrend;

  _VitalStats({
    required this.avgDuration,
    required this.avgGapMinutes,
    required this.count,
    required this.durationTrend,
    required this.gapTrend,
  });
}

class _VitalStatsRow extends StatelessWidget {
  final _VitalStats stats;
  final String periodLabel;

  const _VitalStatsRow({required this.stats, this.periodLabel = '8h'});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.timer,
            label: l10n.avgDuration,
            value: '${stats.avgDuration}s',
            trend: stats.durationTrend,
            trendPositiveIsBad: false,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.swap_vert,
            label: l10n.avgGap,
            value: '${stats.avgGapMinutes}min',
            trend: stats.gapTrend / 60,
            trendPositiveIsBad: true,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.repeat,
            label: l10n.frequency,
            value: '${stats.count}',
            subtitle: l10n.inPeriod(periodLabel),
            color: Colors.purple,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final double? trend;
  final bool trendPositiveIsBad;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.trend,
    this.trendPositiveIsBad = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trendWidget;
    if (trend != null && trend!.abs() > 1) {
      final isUp = trend! > 0;
      final trendColor = (isUp == trendPositiveIsBad)
          ? Colors.orange
          : Colors.green;
      trendWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: trendColor,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                ),
              ),
              if (subtitle != null)
                Text(
                  ' $subtitle',
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              if (trendWidget != null) ...[
                const SizedBox(width: 4),
                trendWidget,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ContractionsGraphPainter extends CustomPainter {
  final List<_Contraction> contractions;
  final int timeWindowHours;

  _ContractionsGraphPainter({
    required this.contractions,
    this.timeWindowHours = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(hours: timeWindowHours));
    final windowDuration = Duration(
      hours: timeWindowHours,
    ).inMilliseconds.toDouble();

    // Draw baseline
    final baselinePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 10),
      Offset(size.width, size.height - 10),
      baselinePaint,
    );

    // Draw hour markers
    for (int i = 0; i <= timeWindowHours; i++) {
      final x = (i / timeWindowHours) * size.width;
      canvas.drawLine(
        Offset(x, size.height - 10),
        Offset(x, size.height - 5),
        baselinePaint,
      );
    }

    // Draw contractions as bars
    for (final contraction in contractions) {
      final startOffset = contraction.startTime
          .difference(windowStart)
          .inMilliseconds
          .toDouble();
      final x = (startOffset / windowDuration) * size.width;

      // Skip if outside visible window
      if (x < 0 || x > size.width) continue;

      // Height based on duration (scale: 30s = 20px, 90s = 60px)
      final maxHeight = size.height - 15;
      final duration = contraction.durationSeconds ?? 30;
      final normalizedDuration = duration.clamp(20, 120);
      final barHeight = (normalizedDuration / 120) * maxHeight;

      // Color based on duration
      Color barColor;
      if (duration >= 60) {
        barColor = Colors.red.shade600;
      } else if (duration >= 45) {
        barColor = Colors.orange.shade600;
      } else {
        barColor = Colors.blue.shade600;
      }

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      // Draw bar (width of 4px, centered on x)
      final barRect = Rect.fromLTWH(
        x - 2,
        size.height - 10 - barHeight,
        4,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TimeframeSelector extends StatelessWidget {
  final int selectedHours;
  final ValueChanged<int> onChanged;

  const _TimeframeSelector({
    required this.selectedHours,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [1, 2, 4, 8];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((hours) {
        final isSelected = hours == selectedHours;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text('${hours}h'),
            selected: isSelected,
            onSelected: (_) => onChanged(hours),
            selectedColor: Colors.purple.shade100,
            labelStyle: TextStyle(
              color: isSelected ? Colors.purple.shade900 : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TimeAxisLabels extends StatelessWidget {
  final int hours;

  const _TimeAxisLabels({required this.hours});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    List<String> labels;
    switch (hours) {
      case 1:
        labels = ['60m', '45m', '30m', '15m', l10n.now];
        break;
      case 2:
        labels = ['2h', '1.5h', '1h', '30m', l10n.now];
        break;
      case 4:
        labels = ['4h', '3h', '2h', '1h', l10n.now];
        break;
      case 8:
      default:
        labels = ['8h', '6h', '4h', '2h', l10n.now];
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.map((label) {
        final isNow = label == l10n.now;
        return Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
