import 'package:bip39/bip39.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_bip32_bip44/dart_bip32_bip44.dart';

class EthereumUtils {
  late http.Client httpClient;
  late Web3Client ethClient;

  static const String _pathForPrivateKey = "m/44'/60'/0'/0/0";
  static String? contractAddress = dotenv.env['CONTRACT_ADDRESS'];
  static String? userAddress = dotenv.env['USER_ADDRESS'];
  static String? mnemonic = dotenv.env['USER_MNEMONIC_PHASE'];
  static int? decimals = int.parse(dotenv.env['DECIMALS_TOKEN']!);

  void initialSetup() async {
    httpClient = http.Client();
    String? api = dotenv.env['BLOCKCHAIN_API'];
    ethClient = Web3Client(api!, httpClient);
  }

  Future getBalance() async {
    EthereumAddress address = EthereumAddress.fromHex(userAddress!);
    List<dynamic> result = await query('balanceOf', [address]);
    return result[0];
  }

  String getPrivateKey(String mnemonic) {
    final Chain chain = _getChainByMnemonic(mnemonic);
    final ExtendedKey extendedKey = chain.forPath(_pathForPrivateKey);
    return extendedKey.privateKeyHex();
  }

  BigInt parseUnits(double amount, int decimals) {
    if (decimals == 0) {
      decimals = 18;
    }
    var multiplyer = '1';
    for (var i = 0; i < decimals; i++) {
      multiplyer += '0';
    }
    return BigInt.from(amount * int.parse(multiplyer));
  }

  String parseAmount(BigInt amount, int decimals) {
    if (decimals == 0) {
      decimals = 18;
    }
    var multiplyer = '1';
    for (var i = 0; i < decimals; i++) {
      multiplyer += '0';
    }
    return (amount.toInt() / int.parse(multiplyer)).toStringAsFixed(2);
  }

  /// Returns BIP32 Root Key
  Chain _getChainByMnemonic(String mnemonic) {
    final String seed = mnemonicToSeedHex(mnemonic); // Returns BIP39 Seed
    return Chain.seed(seed);
  }

  Future<String> transfer(double amount) async {
    EthereumAddress address =
        EthereumAddress.fromHex('0x5Cc9B109c6Db71A04fDfbfDF9E0E9949282D9cA5');
    String privateKey = getPrivateKey(mnemonic!);
    EthPrivateKey credential = EthPrivateKey.fromHex(privateKey);
    DeployedContract contract = await getDeployedContract();
    final ethFunction = contract.function('transfer');
    final parsedAmount = parseUnits(amount, decimals!);
    final result = await ethClient.sendTransaction(
        credential,
        Transaction.callContract(
            contract: contract,
            function: ethFunction,
            parameters: [address, parsedAmount]),
        chainId: (await ethClient.getChainId()).toInt());
    return result.toString();
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await getDeployedContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<DeployedContract> getDeployedContract() async {
    String abi = await rootBundle.loadString("assets/contracts/ERC20.json");
    final contract = DeployedContract(ContractAbi.fromJson(abi, "ERC20"),
        EthereumAddress.fromHex(contractAddress!));
    return contract;
  }
}
