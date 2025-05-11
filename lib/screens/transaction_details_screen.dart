import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction_model.dart';
import '../config/app_config.dart';
import '../utils/snackbar_utils.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;
  final String network;

  const TransactionDetailsScreen({
    Key? key,
    required this.transaction,
    required this.network,
  }) : super(key: key);

  String get etherscanUrl {
    final baseUrl = network == 'mainnet' 
        ? 'https://etherscan.io' 
        : 'https://${network}.etherscan.io';
    return '$baseUrl/tx/${transaction.hash}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSnackBar(context, 'Copied to clipboard');
  }

  Future<void> _openEtherscan() async {
    final url = Uri.parse(etherscanUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(context),
            const SizedBox(height: 16),
            _buildEtherscanButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  transaction.isError ? Icons.error : 
                  transaction.isPending ? Icons.pending : 
                  transaction.isOutgoing ? Icons.call_made : Icons.call_received,
                  color: transaction.isError ? Colors.red : 
                         transaction.isPending ? Colors.orange : 
                         transaction.isOutgoing ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  transaction.statusText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              transaction.formattedValue,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Date', transaction.formattedDate),
            _buildDetailRow(context, 'From', transaction.from),
            _buildDetailRow(context, 'To', transaction.to),
            _buildDetailRow(context, 'Hash', transaction.hash),
            _buildDetailRow(context, 'Gas Used', '${transaction.gasUsed} Wei'),
            _buildDetailRow(context, 'Gas Price', '${transaction.gasPrice} Wei'),
            _buildDetailRow(context, 'Total Gas Cost', transaction.formattedGasCost),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _copyToClipboard(context, value),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.copy, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtherscanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openEtherscan,
        icon: const Icon(Icons.open_in_new),
        label: const Text('View on Etherscan'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
} 