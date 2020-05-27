import 'dart:core';
import 'package:fusecash/models/pro/views/pro_wallet.dart';
import 'package:fusecash/screens/exchange/review_exchange.dart';
import 'package:fusecash/utils/debouncer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fusecash/constans/exchangable_tokens.dart';
import 'package:fusecash/generated/i18n.dart';
import 'package:fusecash/models/app_state.dart';
import 'package:fusecash/models/pro/token.dart';
import 'package:fusecash/screens/exchange/card.dart';
import 'package:fusecash/utils/format.dart';
import 'package:fusecash/widgets/main_scaffold.dart';
import 'package:fusecash/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_segment/flutter_segment.dart';

final _tokens = List<Token>.from(exchangableTokens.values);

class Exchange extends StatefulWidget {
  const Exchange({Key key}) : super(key: key);

  @override
  _ExchangeState createState() => _ExchangeState();
}

class _ExchangeState extends State<Exchange> {
  TextEditingController receiveController = TextEditingController();
  TextEditingController payWithController = TextEditingController();
  Token tokenToPayWith;
  Token tokenToReceive;
  final _payWithDebouncer = Debouncer(milliseconds: 500);
  final _receiveDebouncer = Debouncer(milliseconds: 500);
  bool isFetchingPayWith = false;
  Map swapResponse;
  Map transactionsResponse;
  bool isFetchingReceive = false;
  bool isSwap = false;

  @override
  void dispose() {
    payWithController.dispose();
    receiveController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    tokenToPayWith = _tokens[0];
    tokenToReceive = _tokens[1];
  }

  void getQuateForPayWith(
      String value, String walletAddress, Token token) async {
    try {
      if (this.mounted) {
        setState(() {
          swapResponse = null;
          isFetchingPayWith = true;
        });
      }
      if (value.isEmpty) {
        if (this.mounted) {
          setState(() {
            swapResponse = null;
            receiveController.text = '';
            isFetchingPayWith = false;
          });
        }
        return;
      }
      dynamic response = await fetchSwap(
          walletAddress, token.address, tokenToReceive.address,
          sourceAmount: toBigInt(value, token.decimals).toString());
      swapResponse = Map.from(response['response']['summary'][0]);
      swapResponse['tx'] =
          Map.from(response['response']['transactions'][1]['tx']);
      swapResponse['amount'] = num.parse(value);
      dynamic summary = response['response']['summary'][0];
      String toTokenAmount = formatValue(
          BigInt.from(num.parse(summary['destinationAmount'])),
          tokenToReceive.decimals);
      if (this.mounted) {
        setState(() {
          receiveController.text = toTokenAmount;
          isFetchingPayWith = false;
        });
      }
    } catch (error) {
      if (this.mounted) {
        setState(() {
          swapResponse = null;
          payWithController.text = '';
          receiveController.text = '';
          isFetchingPayWith = false;
        });
      }
    }
  }

  void getQuateForReceive(
      String value, String walletAddress, Token token) async {
    try {
      if (this.mounted) {
        setState(() {
          swapResponse = null;
          isFetchingReceive = true;
        });
      }
      if (value.isEmpty) {
        if (this.mounted) {
          setState(() {
            swapResponse = null;
            payWithController.text = '';
            isFetchingReceive = false;
          });
        }
        return;
      }
      dynamic response = await fetchSwap(
          walletAddress, tokenToReceive.address, token.address,
          sourceAmount: toBigInt(value, tokenToReceive.decimals).toString());
      swapResponse = Map.from(response['response']['summary'][0]);
      swapResponse['tx'] =
          Map.from(response['response']['transactions'][1]['tx']);
      swapResponse['amount'] = num.parse(value);
      dynamic summary = response['response']['summary'][0];
      String fromTokenAmount = formatValue(
          BigInt.from(num.parse(summary['destinationAmount'])), token.decimals);
      if (this.mounted) {
        setState(() {
          payWithController.text = fromTokenAmount;
          isFetchingReceive = false;
        });
      }
    } catch (error) {
      if (this.mounted) {
        setState(() {
          swapResponse = null;
          payWithController.text = '';
          receiveController.text = '';
          isFetchingReceive = false;
        });
      }
    }
  }

  void swap() {
    // if (this.mounted) {
    //   if (isSwap) {
    //     setState(() {
    //       isSwap = !isSwap;
    //       tokenToPayWith = _tokens[0];
    //       tokenToReceive = _tokens[1];
    //     });
    //   } else {
    //     setState(() {
    //       isSwap = !isSwap;
    //       tokenToPayWith = _tokens[1];
    //       tokenToReceive = _tokens[0];
    //     });
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, ProWalletViewModel>(
        distinct: true,
        onInit: (store) {
          Segment.screen(screenName: '/exchange-screen');
        },
        converter: ProWalletViewModel.fromStore,
        builder: (_, viewModel) {
          final List<Token> tokens = viewModel.tokens
              .where((Token token) =>
                  num.parse(formatValue(token.amount, token.decimals)) > 0)
              .toList()
              .reversed
              .toList();
          tokens.sort((a, b) => b.amount.compareTo(a.amount));
          final Token token = tokens[0];
          return MainScaffold(
            automaticallyImplyLeading: false,
            withPadding: true,
            title: I18n.of(context).exchnage,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'Use max',
                            style: TextStyle(fontSize: 16),
                          )
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF4FCFF),
                        border: Border.all(
                          color: Color(0xFFCCE0E8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(9.0)),
                      ),
                      child: Column(
                        children: <Widget>[
                          ExchangeCard(
                            onChanged: (value) {
                              _payWithDebouncer.run(() => getQuateForPayWith(
                                  value, viewModel.walletAddress, token));
                            },
                            walletAddress: viewModel.walletAddress,
                            textEditingController: payWithController,
                            isFetching: isFetchingReceive,
                            tokenToReceive: tokenToReceive,
                            token: token,
                            title: 'Pay with',
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.only(left: 20, right: 20),
                                child: SizedBox(
                                  child: Divider(
                                    thickness: 1.0,
                                    color: Color(0xFFD0E3EA),
                                  ),
                                ),
                              ),
                              InkWell(
                                  onTap: () {
                                    // swap();
                                  },
                                  child: SvgPicture.asset(
                                    'assets/images/swap_icon.svg',
                                    fit: BoxFit.fill,
                                    width: 40,
                                    height: 40,
                                  ))
                            ],
                          ),
                          ExchangeCard(
                            onChanged: (value) {
                              _receiveDebouncer.run(() => getQuateForReceive(
                                  value, viewModel.walletAddress, token));
                            },
                            walletAddress: viewModel.walletAddress,
                            textEditingController: receiveController,
                            isFetching: isFetchingPayWith,
                            tokenToReceive: token,
                            token: tokenToReceive,
                            title: 'Receive',
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
            footer: Center(
              child: PrimaryButton(
                labelFontWeight: FontWeight.normal,
                label: I18n.of(context).exchnage,
                fontSize: 15,
                onPressed: () async {
                  if (swapResponse != null && swapResponse['tx'] != null) {
                    Navigator.push(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => ReviewExchange(
                                  exchangeSummry: swapResponse,
                                )));
                  }
                },
              ),
            ),
          );
        });
  }
}