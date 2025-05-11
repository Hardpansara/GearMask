import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Network'),
            subtitle: Text(walletProvider.currentNetwork),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNetworkSelector(context),
          ),
          const Divider(),
          ListTile(
            title: const Text('View Recovery Phrase'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRecoveryPhraseDialog(context),
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear Wallet'),
            trailing: const Icon(Icons.delete_forever),
            onTap: () => _showClearWalletDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showNetworkSelector(BuildContext context) async {
    final walletProvider = context.read<WalletProvider>();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Network'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConfig.networks.keys.map((network) {
            return ListTile(
              title: Text(network[0].toUpperCase() + network.substring(1)),
              selected: network == walletProvider.currentNetwork,
              onTap: () async {
                await walletProvider.switchNetwork(network);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showRecoveryPhraseDialog(BuildContext context) async {
    final walletProvider = context.read<WalletProvider>();
    final mnemonic = await walletProvider.getMnemonic();
    
    if (context.mounted) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recovery Phrase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write these words down on paper and keep them somewhere safe.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mnemonic ?? 'Error retrieving recovery phrase',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showClearWalletDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wallet'),
        content: const Text(
          'This will delete your wallet from this device. Make sure you have '
          'backed up your recovery phrase before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<WalletProvider>().clearWallet();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
} 