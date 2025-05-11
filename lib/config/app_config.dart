class AppConfig {
  // TODO: Replace with your Infura project ID
  static const String infuraProjectId = '104bae610fd5440d8efbf539024e3b28';
  
  static const Map<String, String> networks = {
    'mainnet': 'https://mainnet.infura.io/v3/$infuraProjectId',
    'goerli': 'https://goerli.infura.io/v3/$infuraProjectId',
    'sepolia': 'https://sepolia.infura.io/v3/$infuraProjectId',
  };

  static const String defaultNetwork = 'sepolia'; // Using testnet by default
  
  // HD Wallet derivation path (BIP44)
  // m/44'/60'/0'/0/0 for Ethereum
  static const String derivationPath = "m/44'/60'/0'/0/0";

  static const etherscanApiKey = 'FSFRAPG1QJIZKGY2PNE89IHY6YR7A1WVX6';
  
  static const Map<String, String> etherscanApis = {
    'mainnet': 'https://api.etherscan.io/api',
    'sepolia': 'https://api-sepolia.etherscan.io/api',
    'goerli': 'https://api-goerli.etherscan.io/api',
  };
} 