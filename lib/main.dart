import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sample/qr_code_reader_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

import 'command_b_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ignore: unused_field
  late WebViewPlusController _controller; // WebViewコントローラー

  //■assetsへの接続
  static const String APPLICATION_URI = 'assets/app/';
  //■react(yarn start)への接続
  //※adb reverse tcp:3000 tcp:3000で、ポートフォーワードすること
  // ignore: constant_identifier_names
  // static const String APPLICATION_URI = 'http://localhost:3000';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ヘッダ3')),
      body: WebViewPlus(
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (controller) {
            _controller = controller;
            _controller.loadUrl(APPLICATION_URI);
          },
          javascriptChannels: <JavascriptChannel>{
            JavascriptChannel(
                name: "__javascriptChannel",
                onMessageReceived: (JavascriptMessage message) async {
                  String? url =
                      await _controller.webViewController.currentUrl();
                  if (url != null && _isAllowUrl(url)) {
                    Map<String, dynamic> jsonMap = json.decode(message.message);
                    var request = Request.fromJson(jsonMap);
                    switch (request.command) {
                      case "a":
                        _commandA(request);
                        break;
                      case "getQrStringFromCamera":
                        await _commandB(request);
                        break;
                    }
                  }
                })
          },
          onPageStarted: (String url) {
            //todo ★許可されたページ以外を外部ブラウザで起動するなどの処置
            // if (!_isAllowUrl(url)) {
            //   _controller.webViewController.goBack();
            //   launchUrl(Uri.parse(url));
            // }
          },
          onPageFinished: (url) {
            //■URLがAPPLICATION_URIである場合、初期化コードを実行する。
            if (_isAllowUrl(url)) {
              _controller.webViewController.runJavascript("""
window.__suppoetedCommands = ["a", "getQrStringFromCamera"];
              """);
            }
          }),
    );
  }

  ///SPAにレスポンスを返却する
  void _returnCommand(String requestId, dynamic result) {
    var encordedResult = jsonEncode(result);
    _controller.webViewController.runJavascript("""
__nativecallback('$requestId', $encordedResult);
              """);
  }

  void _commandA(Request request) {
    var text = request.parameters['text'];
    _returnCommand(request.requestId, {'text': 'command A. text=$text'});
  }

  Future<void> _commandB(Request request) async {
    final result = await Navigator.push<String>(context,
        MaterialPageRoute(builder: (BuildContext context) {
      return const Scaffold(body: QRCodeReaderPage());
    }));

    _returnCommand(request.requestId, result);
    // _returnCommand(request.requestId, "Coomand B.");
  }

  bool _isAllowUrl(String url) {
    //todo ★適当な実装("localhost"が含まれているかどうか)
    return url.startsWith("http://localhost");
  }
}

/// SPAからNativeに送信されるリクエスト
class Request {
  final String command;
  final String requestId;
  final Map<String, dynamic> parameters;

  Request(this.command, this.requestId, this.parameters);

  Request.fromJson(Map<String, dynamic> json)
      : command = json['command'],
        requestId = json['requestId'],
        parameters = json['parameters'];
}

/// NativeからNativeに送信されるレスポンス
class Result {
  final String requestId;
  final dynamic result;

  Result(this.requestId, this.result);

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'result': result,
      };
}
