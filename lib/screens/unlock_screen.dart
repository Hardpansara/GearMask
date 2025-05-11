import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import 'wallet_home_screen.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePin = true;
  int _attempts = 0;
  bool _isLocked = false;
  DateTime? _lockUntil;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlockWallet() async {
    if (_isLocked) {
      setState(() {
        _error = 'Too many attempts. Try again in ${_getRemainingLockTime()}';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isCorrect = await context.read<WalletProvider>().verifyPin(_pinController.text);
      
      if (isCorrect) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WalletHomeScreen()),
          );
        }
      } else {
        _attempts++;
        if (_attempts >= 3) {
          _lockUntil = DateTime.now().add(const Duration(minutes: 5));
          _isLocked = true;
          _error = 'Too many attempts. Try again in 5 minutes';
          _startLockTimer();
        } else {
          _error = 'Incorrect PIN. ${3 - _attempts} attempts remaining';
        }
        _pinController.clear();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startLockTimer() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _attempts = 0;
          _lockUntil = null;
          _error = null;
        });
      }
    });
  }

  String _getRemainingLockTime() {
    if (_lockUntil == null) return '';
    final remaining = _lockUntil!.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 48),
              const Icon(
                Icons.account_balance_wallet,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your PIN to unlock your wallet',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your PIN';
                  }
                  if (value.length < 6) {
                    return 'PIN must be 6 digits';
                  }
                  return null;
                },
                enabled: !_isLocked,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _unlockWallet(),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _isLocked ? null : _unlockWallet,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(_isLocked ? 'Locked' : 'Unlock'),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 