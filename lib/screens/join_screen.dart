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
  bool _skipPairing = false;

  @override
  void initState() {
    super.initState();
    // Don't auto-initiate, let user choose
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _createCaseWithPairing() async {
    final auth = context.read<AuthProvider>();
    setState(() => _isPairing = true);
    
    final success = await auth.initiateCase();
    if (success && mounted) {
      setState(() {
        _newJoinCode = auth.joinCode;
        _newCaseId = auth.caseId;
      });
      _startStatusPolling();
    }
  }

  Future<void> _createCaseWithoutPairing() async {
    final auth = context.read<AuthProvider>();
    setState(() => _skipPairing = true);
    
    final success = await auth.initiateCase();
    if (success && mounted) {
      // Don't wait for claiming, go directly to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
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
        title: Text(widget.isAddingCase ? 'Add New Case' : 'Create Your Case'),
        leading: widget.isAddingCase
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
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
                      onPressed: () {
                        setState(() {
                          _isPairing = false;
                          _skipPairing = false;
                        });
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show pairing screen if user chose to pair
          if (_isPairing && auth.joinCode != null) {
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
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => _createCaseWithoutPairing(),
                      child: const Text('Skip pairing and continue'),
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
          }

          // Initial choice screen
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.pregnant_woman,
                    size: 80,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome to Birth Journal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Track your labor and postpartum journey',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createCaseWithPairing,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Pair with Midwife'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _createCaseWithoutPairing,
                      icon: const Icon(Icons.person),
                      label: const Text('Continue Without Pairing'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'You can pair with a midwife later from settings',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
