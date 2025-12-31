import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/pin_service.dart';
import '../services/secure_storage_service.dart';

class PinSetupScreen extends StatefulWidget {
  final SecureStorageService storage;
  final VoidCallback onPinSet;

  const PinSetupScreen({
    super.key,
    required this.storage,
    required this.onPinSet,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  String? _error;
  bool _isStep2 = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _pinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onPinComplete(String pin) {
    if (!PinService.isValidPin(pin)) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }

    if (!_isStep2) {
      // Move to confirmation step
      setState(() {
        _isStep2 = true;
        _error = null;
      });
      _confirmFocusNode.requestFocus();
    } else {
      // Verify PINs match
      if (pin == _pinController.text) {
        _savePin(pin);
      } else {
        setState(() {
          _error = 'PINs do not match';
          _confirmController.clear();
        });
        _confirmFocusNode.requestFocus();
      }
    }
  }

  Future<void> _savePin(String pin) async {
    final hash = PinService.hashPin(pin);
    await widget.storage.savePinHash(hash);

    // Set session valid for 24 hours
    await widget.storage.saveSessionValidUntil(
      DateTime.now().add(const Duration(hours: 24)),
    );

    widget.onPinSet();
  }

  void _goBack() {
    setState(() {
      _isStep2 = false;
      _error = null;
      _confirmController.clear();
    });
    _pinFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createPin),
        leading: _isStep2
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : null,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isStep2 ? Icons.lock_outline : Icons.lock,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                _isStep2 ? l10n.confirmPin : l10n.createPinDescription,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _PinInput(
                controller: _isStep2 ? _confirmController : _pinController,
                focusNode: _isStep2 ? _confirmFocusNode : _pinFocusNode,
                onCompleted: _onPinComplete,
                autofocus: !_isStep2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 32),
              Text(
                l10n.pinSecurityNote,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onCompleted;
  final bool autofocus;

  const _PinInput({
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
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
            onCompleted(value);
          }
        },
      ),
    );
  }
}
