import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/pin_service.dart';
import '../services/secure_storage_service.dart';

class PinEntryScreen extends StatefulWidget {
  final SecureStorageService storage;
  final VoidCallback onPinVerified;

  const PinEntryScreen({
    super.key,
    required this.storage,
    required this.onPinVerified,
  });

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  String? _error;
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyPin(String pin) async {
    if (!PinService.isValidPin(pin)) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }

    final storedHash = await widget.storage.getPinHash();
    if (storedHash == null) {
      // No PIN stored, this shouldn't happen
      widget.onPinVerified();
      return;
    }

    if (PinService.verifyPin(pin, storedHash)) {
      // PIN correct - extend session
      await widget.storage.saveSessionValidUntil(
        DateTime.now().add(const Duration(hours: 24)),
      );
      widget.onPinVerified();
    } else {
      _attempts++;
      if (_attempts >= _maxAttempts) {
        // Too many attempts - could lock out or reset
        setState(() => _error = 'Too many incorrect attempts');
      } else {
        setState(() {
          _error =
              'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.';
          _pinController.clear();
        });
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              Text(
                l10n.enterPin,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enterPinDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _pinController,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  obscureText: true,
                  maxLength: 4,
                  style: const TextStyle(fontSize: 32, letterSpacing: 16),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                    hintText: '• • • •',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (value) {
                    if (value.length == 4) {
                      _verifyPin(value);
                    }
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
