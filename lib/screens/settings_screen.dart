import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/biometric_auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _canUseBiometric = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final canUse = await _biometricService.canUseBiometric();
    final bioEnabled = await _biometricService.isBiometricEnabled();
    final pinEnabled = await _biometricService.isPINEnabled();

    setState(() {
      _canUseBiometric = canUse;
      _biometricEnabled = bioEnabled;
      _pinEnabled = pinEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !_canUseBiometric) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication not available on this device')),
      );
      return;
    }

    if (value) {
      // Test biometric authentication
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed')),
        );
        return;
      }
    }

    setState(() => _biometricEnabled = value);
    if (value) {
      await _biometricService.enableBiometric();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication enabled')),
      );
    } else {
      await _biometricService.disableBiometric();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication disabled')),
      );
    }
  }

  Future<void> _togglePIN(bool value) async {
    if (value) {
      // Show PIN setup dialog
      final result = await _showPINSetupDialog();
      if (result != null && result.isNotEmpty) {
        await _biometricService.savePIN(result);
        await _biometricService.enablePIN();
        setState(() => _pinEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN authentication enabled')),
        );
      }
    } else {
      await _biometricService.disablePIN();
      await _biometricService.clearPIN();
      setState(() => _pinEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN authentication disabled')),
      );
    }
  }

  Future<String?> _showPINSetupDialog() async {
    String? pin;
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _PINSetupDialog(onPINSet: (value) {
          pin = value;
        });
      },
    );
    
    return result ?? pin;
  }

  Future<void> _changePIN() async {
    final newPIN = await _showPINSetupDialog();
    if (newPIN != null && newPIN.isNotEmpty) {
      await _biometricService.savePIN(newPIN);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated successfully')),
      );
    }
  }

  Future<void> _pairWithMidwife() async {
    final joinCodeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pair with Midwife'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the join code from your midwife'),
            const SizedBox(height: 16),
            TextField(
              controller: joinCodeController,
              decoration: const InputDecoration(
                labelText: 'Join Code (6 characters)',
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final code = joinCodeController.text.trim().toUpperCase();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Join code must be 6 characters')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final code = joinCodeController.text.trim().toUpperCase();
      final auth = context.read<AuthProvider>();
      final apiClient = context.read<ApiClient>();

      try {
        await apiClient.pairMidwife(auth.caseId!, code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully paired with midwife!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pair: $e')),
          );
        }
      }
    }
  }

  Future<void> _unpairMidwife() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Midwife'),
        content: const Text('Are you sure you want to unpair from your midwife?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final apiClient = context.read<ApiClient>();

      try {
        await apiClient.unpairMidwife(auth.caseId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unpaired from midwife')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unpair: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Midwife Pairing Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Midwife Pairing',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pair your case with a midwife to receive professional support',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pairWithMidwife,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Pair with Midwife'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _unpairMidwife,
                                icon: const Icon(Icons.link_off),
                                label: const Text('Unpair Midwife'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Biometric Authentication Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometric Authentication',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _canUseBiometric
                              ? 'Use fingerprint or face recognition to authenticate'
                              : 'Biometric authentication not available on this device',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Enable Biometric Auth'),
                          value: _biometricEnabled && _canUseBiometric,
                          onChanged: _canUseBiometric ? _toggleBiometric : null,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // PIN Authentication Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PIN Authentication',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use a numeric PIN code to authenticate',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Enable PIN Auth'),
                          value: _pinEnabled,
                          onChanged: _togglePIN,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_pinEnabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Change PIN'),
                              onPressed: _changePIN,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PINSetupDialog extends StatefulWidget {
  final Function(String?) onPINSet;

  const _PINSetupDialog({required this.onPINSet});

  @override
  State<_PINSetupDialog> createState() => _PINSetupDialogState();
}

class _PINSetupDialogState extends State<_PINSetupDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setupPIN() {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    setState(() => _errorMessage = null);

    if (pin.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'PIN cannot be empty');
      return;
    }

    if (pin.length < 4 || pin.length > 6) {
      setState(() => _errorMessage = 'PIN must be 4-6 digits');
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      setState(() => _errorMessage = 'PIN must contain only numbers');
      return;
    }

    if (pin != confirm) {
      setState(() => _errorMessage = 'PINs do not match');
      return;
    }

    widget.onPINSet(pin);
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set PIN'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'PIN (4-6 digits)',
                errorText: _errorMessage,
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _setupPIN,
          child: const Text('Set PIN'),
        ),
      ],
    );
  }
}
