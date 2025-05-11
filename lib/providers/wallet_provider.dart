import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3dart/web3dart.dart';
import 'package:crypto/crypto.dart';
import '../services/wallet_service.dart';
import '../models/transaction_model.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService;
  final _storage = const FlutterSecureStorage();
  
  String? _address;
  BigInt _balance = BigInt.zero;
  bool _isLoading = false;
  String? _error;
  String _currentNetwork = 'sepolia';
  bool _isUnlocked = false;
  List<TransactionModel> _transactions = [];
  bool _isRefreshing = false;

  String? get address => _address;
  BigInt get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentNetwork => _currentNetwork;
  bool get isUnlocked => _isUnlocked;
  List<TransactionModel> get transactions => _transactions;
  bool get isRefreshing => _isRefreshing;

  WalletProvider(this._walletService) {
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    try {
      await _initializeNetwork();
      await _loadWalletData();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing wallet: $e');
    }
  }

  Future<void> reloadApp() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Reset all data
      _balance = BigInt.zero;
      _transactions = [];
      
      // Reinitialize everything
      await _initializeWallet();
      
      if (_address != null) {
        await refreshWallet();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error reloading app: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeNetwork() async {
    _currentNetwork = await _walletService.getCurrentNetwork();
    if (_address != null) {
      await refreshWallet();
    }
    notifyListeners();
  }

  Future<bool> hasWallet() async {
    return await _walletService.hasWallet();
  }

  Future<String?> createWallet() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final mnemonic = await _walletService.createWallet();
      await _loadWalletData();
      
      return mnemonic;
      
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importWallet(String mnemonic) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _walletService.importWallet(mnemonic);
      await _loadWalletData();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadWalletData() async {
    try {
      _isLoading = true;
      notifyListeners();

      _address = await _walletService.getAddress();
      if (_address != null) {
        await refreshWallet();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading wallet data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWallet() async {
    if (_isRefreshing) return;
    
    try {
      _isRefreshing = true;
      _error = null;
      notifyListeners();

      // Update balance
      if (_address != null) {
        _balance = await _walletService.getBalance();
      }

      // Update transaction history
      if (_address != null) {
        _transactions = await _walletService.getTransactionHistory(_address!);
      }

    } catch (e) {
      _error = e.toString();
      debugPrint('Error refreshing wallet: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<String> sendTransaction({
    required String toAddress,
    required BigInt amount,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final txHash = await _walletService.sendTransaction(
        toAddress: toAddress,
        amount: amount,
      );

      // Wait a moment before refreshing to allow the blockchain to update
      await Future.delayed(const Duration(seconds: 2));
      await refreshWallet();

      return txHash;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error in WalletProvider.sendTransaction: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchNetwork(String network) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _walletService.switchNetwork(network);
      _currentNetwork = network;
      await refreshWallet();
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getMnemonic() async {
    return await _walletService.getMnemonic();
  }

  Future<void> clearWallet() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _walletService.clearWallet();
      _address = null;
      _balance = BigInt.zero;
      _isUnlocked = false;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PIN functionality
  Future<void> setupPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: 'wallet_pin', value: hashedPin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: 'wallet_pin');
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isCorrect = storedHash == inputHash;
    
    if (isCorrect) {
      _isUnlocked = true;
      notifyListeners();
    }
    
    return isCorrect;
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: 'wallet_pin');
    return pin != null;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  void lock() {
    _isUnlocked = false;
    notifyListeners();
  }

  Future<bool> verifyPrivateKey(String privateKey) async {
    return _walletService.verifyPrivateKey(privateKey);
  }

  Future<bool> verifyMnemonic(String mnemonic) async {
    return _walletService.verifyMnemonic(mnemonic);
  }

  Future<String?> getPrivateKey() async {
    return _walletService.getPrivateKey();
  }

  Future<List<TransactionModel>> getTransactionHistory(String address) async {
    return _walletService.getTransactionHistory(address);
  }

  Future<String> getCurrentNetwork() async {
    return _walletService.getCurrentNetwork();
  }

  String get formattedBalance {
    if (_balance == null) return '0.0';
    final inEther = EtherAmount.fromBigInt(EtherUnit.wei, _balance!).getValueInUnit(EtherUnit.ether);
    return inEther.toStringAsFixed(4);
  }

  Future<String?> getAddress() async {
    if (_address != null) return _address;
    _address = await _walletService.getAddress();
    return _address;
  }
} 