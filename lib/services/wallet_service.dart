import 'dart:convert';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:hex/hex.dart';
import '../config/app_config.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'dart:math';
import '../models/transaction_model.dart';
import 'package:flutter/foundation.dart';

class WalletService {
  static const _storage = FlutterSecureStorage();
  static const _mnemonicKey = 'mnemonic_key';
  static const _privateKeyKey = 'private_key';
  static const _networkKey = 'network_key';
  
  late Web3Client _client;
  late EthPrivateKey _credentials;
  String _currentNetwork = AppConfig.defaultNetwork;
  
  WalletService() {
    _initializeClient();
  }

  void _initializeClient() {
    final rpcUrl = AppConfig.networks[_currentNetwork]!;
    _client = Web3Client(rpcUrl, http.Client());
  }

  static Future<Uint8List> deriveKeyFromSeed(Uint8List seed) async {
    try {
      final masterKey = await ED25519_HD_KEY.getMasterKeyFromSeed(seed);
      // Convert the private key to Uint8List
      return Uint8List.fromList(masterKey.key);
    } catch (e) {
      throw Exception('Error deriving private key: $e');
    }
  }

  Future<void> _loadCredentials() async {
    final privateKeyHex = await _storage.read(key: _privateKeyKey);
    if (privateKeyHex != null) {
      _credentials = EthPrivateKey.fromHex(privateKeyHex);
    }
  }

  Future<void> switchNetwork(String network) async {
    if (!AppConfig.networks.containsKey(network)) {
      throw Exception('Network not supported');
    }
    _currentNetwork = network;
    await _storage.write(key: _networkKey, value: network);
    _initializeClient();
  }

  Future<String> getCurrentNetwork() async {
    final network = await _storage.read(key: _networkKey);
    return network ?? AppConfig.defaultNetwork;
  }

  Future<String> createWallet() async {
    try {
      // Generate a new random mnemonic
      final mnemonic = bip39.generateMnemonic();
      
      // Create seed from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = HEX.encode(seed.sublist(0, 32));
      
      // Store the mnemonic and private key securely
      await _storage.write(key: _mnemonicKey, value: mnemonic);
      await _storage.write(key: _privateKeyKey, value: privateKey);
      
      return mnemonic;
    } catch (e) {
      throw Exception('Error creating wallet: $e');
    }
  }

  Future<String?> getMnemonic() async {
    return await _storage.read(key: _mnemonicKey);
  }

  Future<EthereumAddress> getPublicAddress() async {
    final privateKeyHex = await _storage.read(key: _privateKeyKey);
    if (privateKeyHex == null) throw Exception('No wallet found');
    
    final privateKey = EthPrivateKey.fromHex(privateKeyHex);
    return privateKey.address;
  }

  Future<BigInt> getBalance() async {
    final address = await getPublicAddress();
    final balance = await _client.getBalance(address);
    return balance.getInWei;
  }

  Future<String> sendTransaction({
    required String toAddress,
    required BigInt amount,
  }) async {
    try {
      debugPrint('Starting transaction...');
      final privateKeyHex = await _storage.read(key: _privateKeyKey);
      if (privateKeyHex == null) throw Exception('No wallet found');
      
      debugPrint('Creating credentials...');
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final from = credentials.address;
      final to = EthereumAddress.fromHex(toAddress);
      
      // Get the current gas price with 10% extra for faster confirmation
      debugPrint('Getting gas price...');
      final gasPrice = await _client.getGasPrice();
      final adjustedGasPrice = EtherAmount.fromBigInt(
        EtherUnit.wei,
        (gasPrice.getInWei * BigInt.from(110)) ~/ BigInt.from(100),
      );
      
      debugPrint('Estimating gas...');
      // Estimate gas limit for the transaction
      final gasLimit = await _client.estimateGas(
        sender: from,
        to: to,
        value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
      );

      // Add 20% buffer to gas limit for safety
      final safeGasLimit = (gasLimit * BigInt.from(120)) ~/ BigInt.from(100);
      
      debugPrint('Creating transaction...');
      final chainId = await _getChainId();
      final transaction = Transaction(
        from: from,
        to: to,
        value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
        gasPrice: adjustedGasPrice,
        maxGas: safeGasLimit.toInt(),
        nonce: await _client.getTransactionCount(from),
      );

      // Check if we have enough balance for transaction + gas
      final totalCost = amount + (adjustedGasPrice.getInWei * safeGasLimit);
      final currentBalance = await getBalance();
      
      debugPrint('Checking balance... Total cost: $totalCost, Current balance: $currentBalance');
      if (totalCost > currentBalance) {
        throw Exception('Insufficient balance to cover transaction and gas fees');
      }
      
      // Send the transaction and get the hash
      debugPrint('Sending transaction...');
      final txHash = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: chainId,
      );
      debugPrint('Transaction hash: $txHash');

      // Wait for transaction to be mined
      bool confirmed = false;
      int attempts = 0;
      const maxAttempts = 30; // Wait up to 30 attempts (about 2 minutes)

      debugPrint('Waiting for confirmation...');
      while (!confirmed && attempts < maxAttempts) {
        try {
          final receipt = await _client.getTransactionReceipt(txHash);
          if (receipt != null) {
            debugPrint('Transaction status: ${receipt.status}');
            if (receipt.status!) {
              confirmed = true;
              debugPrint('Transaction confirmed!');
            } else {
              throw Exception('Transaction failed on blockchain');
            }
          }
        } catch (e) {
          debugPrint('Waiting for confirmation... Attempt ${attempts + 1}: $e');
        }

        if (!confirmed) {
          attempts++;
          await Future.delayed(const Duration(seconds: 4));
        }
      }

      if (!confirmed) {
        throw Exception('Transaction not confirmed after ${maxAttempts * 4} seconds');
      }

      return txHash;
    } catch (e) {
      debugPrint('Transaction error: $e');
      if (e.toString().contains('insufficient funds')) {
        throw Exception('Insufficient balance to cover transaction and gas fees');
      }
      throw Exception('Error sending transaction: $e');
    }
  }

  Future<int> _getChainId() async {
    switch (_currentNetwork) {
      case 'mainnet':
        return 1;
      case 'goerli':
        return 5;
      case 'sepolia':
        return 11155111;
      default:
        throw Exception('Unknown network');
    }
  }

  Future<void> importWallet(String mnemonic) async {
    try {
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }
      
      // Create seed from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = HEX.encode(seed.sublist(0, 32));
      
      await _storage.write(key: _mnemonicKey, value: mnemonic);
      await _storage.write(key: _privateKeyKey, value: privateKey);
    } catch (e) {
      throw Exception('Error importing wallet: $e');
    }
  }

  Future<void> clearWallet() async {
    await _storage.deleteAll();
  }

  Future<bool> hasWallet() async {
    final privateKey = await _storage.read(key: _privateKeyKey);
    return privateKey != null;
  }

  Future<String?> getAddress() async {
    final privateKey = await _storage.read(key: _privateKeyKey);
    if (privateKey == null) return null;

    final credentials = EthPrivateKey.fromHex(privateKey);
    return credentials.address.hexEip55;
  }

  Future<List<TransactionModel>> getTransactionHistory(String address) async {
    try {
      final apiUrl = AppConfig.etherscanApis[_currentNetwork];
      if (apiUrl == null) {
        throw Exception('Network not supported for transaction history');
      }

      final url = Uri.parse('$apiUrl'
          '?module=account'
          '&action=txlist'
          '&address=$address'
          '&startblock=0'
          '&endblock=99999999'
          '&page=1'
          '&offset=50'  // Get last 50 transactions
          '&sort=desc'  // Latest first
          '&apikey=${AppConfig.etherscanApiKey}');

      debugPrint('Fetching transaction history from: $url');
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == '1' && data['result'] is List) {
        final transactions = (data['result'] as List).map((tx) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(tx['timeStamp']) * 1000,
          );
          
          final value = BigInt.parse(tx['value']);
          final isError = tx['isError'] == '1';
          final confirmations = int.parse(tx['confirmations']);
          
          return TransactionModel(
            hash: tx['hash'],
            from: tx['from'],
            to: tx['to'],
            value: value,
            timestamp: timestamp,
            isOutgoing: tx['from'].toLowerCase() == address.toLowerCase(),
            isPending: confirmations < 12,  // Consider pending if less than 12 confirmations
            isError: isError,
            gasUsed: tx['gasUsed'],
            gasPrice: tx['gasPrice'],
          );
        }).toList();

        debugPrint('Found ${transactions.length} transactions');
        return transactions;
      } else {
        debugPrint('Error fetching transactions: ${data['message']}');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getTransactionHistory: $e');
      return [];
    }
  }

  /// Verifies if the provided private key matches the current wallet's private key
  Future<bool> verifyPrivateKey(String privateKey) async {
    try {
      await _loadCredentials();
      final currentKey = await _storage.read(key: _privateKeyKey);
      if (currentKey == null) return false;

      final providedKey = privateKey.startsWith('0x') ? privateKey.substring(2) : privateKey;
      return providedKey.toLowerCase() == currentKey.toLowerCase();
    } catch (e) {
      debugPrint('Error verifying private key: $e');
      return false;
    }
  }

  /// Gets the private key of the current wallet (should be used carefully)
  Future<String?> getPrivateKey() async {
    try {
      final privateKey = await _storage.read(key: _privateKeyKey);
      if (privateKey == null) return null;
      return '0x$privateKey';
    } catch (e) {
      debugPrint('Error getting private key: $e');
      return null;
    }
  }

  /// Verifies if the provided mnemonic can generate the current wallet
  Future<bool> verifyMnemonic(String mnemonic) async {
    try {
      await _loadCredentials();
      if (_credentials.address == null) return false;

      final seed = bip39.mnemonicToSeed(mnemonic);
      final derivedKey = await compute(deriveKeyFromSeed, seed);
      final derivedCredentials = EthPrivateKey.fromHex(HEX.encode(derivedKey));
      
      return derivedCredentials.address == _credentials.address;
    } catch (e) {
      debugPrint('Error verifying mnemonic: $e');
      return false;
    }
  }
} 