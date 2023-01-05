// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as https;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: HomeWidget(),
      ),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final connector = WalletConnect(
    bridge: 'https://bridge.walletconnect.org',
    clientMeta: const PeerMeta(
      name: 'WalletConnect',
      description: 'WalletConnect Developer App',
      url: 'https://walletconnect.org',
      icons: [
        // Wallet Connect logo
        'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
      ],
    ),
  );

  final peerMeta = const PeerMeta(
    name: 'Nowly App',
    description: 'Nowly requesting authentication',
    url: 'https://example.walletconnect.org/',
    icons: [
      // Wallet Connect logo
      'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
    ],
  );

  final contractAddress =
      EthereumAddress.fromHex('0x2c4D8F3d5A20E2147B731ddA6B6C512d9609Af78');

  final abi = [];

  late ContractAbi contractAbi;

  ContractFunction contractFunction = const ContractFunction(
    "mint",
    [
      FunctionParameter("account", AddressType()),
      FunctionParameter("amount", UintType()),
    ],
  );

  late EthereumWalletConnectProvider provider;

  late SessionStatus session;

  late Web3Client ethereum;

  late String _uri = "";

  @override
  void initState() {
    connector.on('session_request', (payload) => print('payload $payload'));

    connector.on('disconnect', (event) => print('disconnected'));

    connector.on('call_request', (event) => print('call request $event'));

    connector.on(
        'wc_sessionRequest', (event) => print('session request $event'));

    contractAbi = ContractAbi(
      "mint",
      [contractFunction],
      [],
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: () async {
              if (!connector.connected) {
                session = await connector.connect(
                  chainId: 5,
                  onDisplayUri: (uri) async {
                    if (_uri == "") _uri = uri;

                    print(uri);

                    await launchUrlString(_uri,
                        mode: LaunchMode.externalApplication);
                  },
                );

                launchUrlString(_uri, mode: LaunchMode.externalApplication);
                await connector.updateSession(session);
                await connector.killSession();
                print('session update');
              } else {
                print('session active');
              }

              if (connector.connected) {
                provider = EthereumWalletConnectProvider(connector);

                ethereum = Web3Client(
                  'wss://ws-nd-077-834-223.p2pify.com/4da16d128b50297118b38fca4e767a87',
                  https.Client(),
                );
              }

              print('accounts ${session.accounts}');
              print('session $session');
              print('network id ${session.networkId}');
              print('chain id ${session.chainId}');

              return;
            },
            child: const Text('Authenticate'),
          ),
          const SizedBox(
            height: 10,
          ),
          OutlinedButton(
            onPressed: () async {
              final sender = EthereumAddress.fromHex(session.accounts[0]);

              launchUrlString(
                _uri,
                mode: LaunchMode.externalApplication,
              );

              final transaction = Transaction.callContract(
                from: sender,
                contract: DeployedContract(
                  contractAbi,
                  contractAddress,
                ),
                function: contractFunction,
                parameters: [sender, BigInt.from(1)],
              );

              final credentials =
                  WalletConnectEthereumCredentials(provider: provider);

              final txHash = await ethereum.sendTransaction(
                credentials,
                transaction,
                chainId: 5,
              );

              print('transaction hash: $txHash');
            },
            child: const Text('Test transaction'),
          ),
          const SizedBox(
            height: 10,
          ),
          OutlinedButton(
            onPressed: () async {
              final close = connector.close(forceClose: true);
              print(close);

              final kill = connector.killSession();
              print(kill);

              _uri = "";

              print('logged out');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class WalletConnectEthereumCredentials extends CustomTransactionSender {
  WalletConnectEthereumCredentials({required this.provider});

  final EthereumWalletConnectProvider provider;

  @override
  Future<EthereumAddress> extractAddress() {
    throw UnimplementedError();
  }

  @override
  Future<String> sendTransaction(Transaction transaction) async {
    final hash = await provider.sendTransaction(
      from: transaction.from!.hex,
      to: transaction.to?.hex,
      data: transaction.data,
      gas: transaction.maxGas,
      gasPrice: transaction.gasPrice?.getInWei,
      value: transaction.value?.getInWei,
      nonce: transaction.nonce,
    );

    return hash;
  }

  @override
  Future<MsgSignature> signToSignature(Uint8List payload,
      {int? chainId, bool isEIP1559 = false}) {
    throw UnimplementedError();
  }
}
