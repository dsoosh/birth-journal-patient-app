import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';

class JoinScreen extends StatefulWidget {
  final bool isAddingCase;

  const JoinScreen({super.key, this.isAddingCase = false});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  Timer? _statusTimer;
  String? _newJoinCode;
  String? _newCaseId;
  bool _isPairing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateIfNeeded();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _initiateIfNeeded() async {
    final auth = context.read<AuthProvider>();
    
    if (widget.isAddingCase) {
      // Always initiate a new case when adding
      setState(() => _isPairing = true);
      final success = await auth.initiateCase();
      if (success && mounted) {
        setState(() {
          _newJoinCode = auth.joinCode;
          _newCaseId = auth.caseId;
        });
        _startStatusPolling();
      }
    } else if (auth.joinCode == null) {
      await auth.initiateCase();
      if (mounted && !auth.claimed) {
        _startStatusPolling();
      }
    } else if (!auth.claimed) {
      _startStatusPolling();
    }
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final auth = context.read<AuthProvider>();
      await auth.checkClaimed();
      if (auth.claimed && mounted) {
        timer.cancel();
        if (widget.isAddingCase) {
          // Go back to home screen after adding new case
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAddingCase ? 'Add New Case' : 'Pair with your midwife'),
        leading: widget.isAddingCase
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading && auth.joinCode == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (auth.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(auth.error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => auth.initiateCase(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (auth.joinCode == null) {
            return const Center(child: Text('Initializing...'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Show this code to your midwife',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: auth.joinCode!,
                    version: QrVersions.auto,
                    size: 250,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  auth.joinCode!,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                if (!auth.claimed) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text(
                    'Waiting for midwife to pair...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ] else ...[
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Paired successfully!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
