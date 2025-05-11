import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';
import '../providers/wallet_provider.dart';

class SendTransactionScreen extends StatefulWidget {
  const SendTransactionScreen({super.key});

  @override
  State<SendTransactionScreen> createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _sendTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Show initial progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending transaction...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Convert ETH amount to Wei
      final ethAmount = double.parse(_amountController.text);
      final weiAmount = BigInt.from(ethAmount * 1e18); // Convert ETH to Wei

      // Send transaction and wait for confirmation
      await context.read<WalletProvider>().sendTransaction(
        toAddress: _addressController.text,
        amount: weiAmount,
      );

      // Update the wallet data after successful transaction
      await context.read<WalletProvider>().refreshWallet();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Transaction confirmed successfully'),
                ),
                TextButton(
                  onPressed: () {
                    // You can add a link to view the transaction on Etherscan here
                  },
                  child: const Text(
                    'View',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error ?? 'Transaction failed'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an address';
    }
    if (!value.startsWith('0x')) {
      return 'Address must start with 0x';
    }
    if (value.length != 42) {
      return 'Invalid address length';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than 0';
      }
      
      // Check if amount exceeds balance
      final provider = context.read<WalletProvider>();
      final balanceInEth = EtherAmount.fromBigInt(
        EtherUnit.wei,
        provider.balance,
      ).getValueInUnit(EtherUnit.ether);
      
      // Add some buffer for gas fees (0.0001 ETH)
      if (amount >= balanceInEth - 0.0001) {
        return 'Insufficient balance (need some ETH for gas fees)';
      }
    } catch (e) {
      return 'Invalid amount';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final balanceInEth = EtherAmount.fromBigInt(
      EtherUnit.wei,
      provider.balance,
    ).getValueInUnit(EtherUnit.ether);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send ETH'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${balanceInEth.toStringAsFixed(6)} ETH',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Address',
                    hintText: '0x...',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (ETH)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateAmount,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _sendTransaction,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send Transaction'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 