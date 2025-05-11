import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/snackbar_utils.dart';

class VerifyCredentialsScreen extends StatefulWidget {
  const VerifyCredentialsScreen({Key? key}) : super(key: key);

  @override
  State<VerifyCredentialsScreen> createState() => _VerifyCredentialsScreenState();
}

class _VerifyCredentialsScreenState extends State<VerifyCredentialsScreen> {
  final _privateKeyController = TextEditingController();
  final _mnemonicController = TextEditingController();
  bool _showPrivateKey = false;
  String? _currentPrivateKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivateKey();
  }

  Future<void> _loadPrivateKey() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _currentPrivateKey = await walletProvider.getPrivateKey();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _verifyPrivateKey() async {
    if (_privateKeyController.text.isEmpty) {
      showSnackBar(context, 'Please enter a private key');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final walletProvider = context.read<WalletProvider>();
      final isValid = await walletProvider.verifyPrivateKey(_privateKeyController.text);
      
      showSnackBar(
        context, 
        isValid ? 'Private key verified successfully!' : 'Invalid private key',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyMnemonic() async {
    if (_mnemonicController.text.isEmpty) {
      showSnackBar(context, 'Please enter your recovery phrase');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final walletProvider = context.read<WalletProvider>();
      final isValid = await walletProvider.verifyMnemonic(_mnemonicController.text);
      
      showSnackBar(
        context, 
        isValid ? 'Recovery phrase verified successfully!' : 'Invalid recovery phrase',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyPrivateKey() {
    if (_currentPrivateKey != null) {
      Clipboard.setData(ClipboardData(text: _currentPrivateKey!));
      showSnackBar(context, 'Private key copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Wallet Credentials'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Private Key',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_currentPrivateKey != null)
                      InkWell(
                        onTap: _copyPrivateKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _showPrivateKey 
                                  ? _currentPrivateKey! 
                                  : '${_currentPrivateKey!.substring(0, 10)}...${_currentPrivateKey!.substring(_currentPrivateKey!.length - 8)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(_showPrivateKey ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _showPrivateKey = !_showPrivateKey),
                            ),
                            const Icon(Icons.copy),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Private Key',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _privateKeyController,
              decoration: const InputDecoration(
                labelText: 'Enter Private Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPrivateKey,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verify Private Key'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Recovery Phrase',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mnemonicController,
              decoration: const InputDecoration(
                labelText: 'Enter Recovery Phrase',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyMnemonic,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verify Recovery Phrase'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _privateKeyController.dispose();
    _mnemonicController.dispose();
    super.dispose();
  }
} 