import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutterdapptest/models/eth_utils.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter dApp Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static int? decimals = int.parse(dotenv.env['DECIMALS_TOKEN']!);
  EthereumUtils ethUtils = EthereumUtils();
  String userBalance = 'Loading...';
  String trxHash = '';
  bool isTransferring = false;

  void getUserBalance() async {
    userBalance = 'Loading...';
    var balance = await ethUtils.getBalance();
    var formattedBalance = ethUtils.parseAmount(balance, decimals!);
    setState(() {
      userBalance = formattedBalance;
    });
  }

  void transferToken() async {
    isTransferring = true;
    double transferAmount = 1;
    var hash = await ethUtils.transfer(transferAmount);
    setState(() {
      trxHash = hash;
      userBalance = (double.parse(userBalance) - transferAmount).toString();
      isTransferring = false;
    });
  }

  @override
  void initState() {
    super.initState();
    ethUtils.initialSetup();
    getUserBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Flutter Test dApp')),
        body: <Widget>[
          Center(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('User Balance: $userBalance',
                    textAlign: TextAlign.justify)),
          ),
          TextButton(
            onPressed: isTransferring ? null : transferToken,
            child: const Text('Transfer 1 Token'),
          ),
          trxHash.isNotEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Trx Hash: $trxHash',
                          textAlign: TextAlign.justify)),
                )
              : Container(),
        ].toColumn());
  }
}
