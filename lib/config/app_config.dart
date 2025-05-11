class AppConfig {
  // TODO: Replace with your Infura project ID
  static const String infuraProjectId = 'YOUR-API';
  
  static const Map<String, String> networks = {
    'mainnet': 'YOUR-API',
    'goerli': 'YOUR-API',
    'sepolia': 'YOUR-API',
  };

  static const String defaultNetwork = 'sepolia'; // Using testnet by default
  
  // HD Wallet derivation path (BIP44)
  // m/44'/60'/0'/0/0 for Ethereum
  static const String derivationPath = "m/44'/60'/0'/0/0";

  static const etherscanApiKey = 'YOUR-API';
  
  static const Map<String, String> etherscanApis = {
    'mainnet': 'https://api.etherscan.io/api',
    'sepolia': 'https://api-sepolia.etherscan.io/api',
    'goerli': 'https://api-goerli.etherscan.io/api',
  };
} 