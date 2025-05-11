import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wallet_home_screen.dart';

class BackupMnemonicScreen extends StatefulWidget {
  final String mnemonic;

  const BackupMnemonicScreen({
    super.key,
    required this.mnemonic,
  });

  @override
  State<BackupMnemonicScreen> createState() => _BackupMnemonicScreenState();
}

class _BackupMnemonicScreenState extends State<BackupMnemonicScreen> {
  bool _hasCopied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.mnemonic));
    setState(() => _hasCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recovery phrase copied to clipboard'),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const WalletHomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Recovery Phrase'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Your Recovery Phrase',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Write down these 12 words in order and store them in a safe place. Never share them with anyone!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth > 500 ? 4 : 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: words.length,
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  words[index],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: Icon(_hasCopied ? Icons.check : Icons.copy),
                label: Text(_hasCopied ? 'Copied' : 'Copy to Clipboard'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _navigateToHome,
                child: const Text("I've Saved My Recovery Phrase"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
} 