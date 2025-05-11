import 'package:web3dart/web3dart.dart';

class TransactionModel {
  final String hash;
  final String from;
  final String to;
  final BigInt value;
  final DateTime timestamp;
  final bool isPending;
  final bool isOutgoing;
  final bool isError;
  final String gasUsed;
  final String gasPrice;

  TransactionModel({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.timestamp,
    this.isPending = false,
    required this.isOutgoing,
    this.isError = false,
    required this.gasUsed,
    required this.gasPrice,
  });

  String get formattedValue {
    final inEther = EtherAmount.fromBigInt(EtherUnit.wei, value).getValueInUnit(EtherUnit.ether);
    return '${inEther.toStringAsFixed(6)} ETH';
  }

  String get shortHash {
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }

  String get formattedDate {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
           '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    if (isError) return 'Failed';
    if (isPending) return 'Pending';
    return isOutgoing ? 'Sent' : 'Received';
  }

  String get formattedGasCost {
    final gasPriceBigInt = BigInt.parse(gasPrice);
    final gasUsedBigInt = BigInt.parse(gasUsed);
    final totalGasCost = gasPriceBigInt * gasUsedBigInt;
    final inEther = EtherAmount.fromBigInt(EtherUnit.wei, totalGasCost).getValueInUnit(EtherUnit.ether);
    return '${inEther.toStringAsFixed(8)} ETH';
  }

  String get shortAddress {
    return '${to.substring(0, 6)}...${to.substring(to.length - 4)}';
  }
} 