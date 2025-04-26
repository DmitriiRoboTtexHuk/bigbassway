import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(


      home: WebViewScreen(),
    );
  }
}


class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebViewController webViewController;
  late SimpleFontelicoProgressDialog _dialog;
  bool isDialogVisible = false; // Локальное состояние для отслеживания диалога

  @override
  void initState() {
    super.initState();
    // Инициализация загрузочного диалога
    _dialog = SimpleFontelicoProgressDialog(
      context: context,
      barrierDimisable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://bass-way-big-bass.online/bwbb/'),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              _showLoader(); // Показываем диалог при начале загрузки
            },
            onLoadStop: (controller, url) async {
              _hideLoader(); // Скрываем диалог после завершения загрузки
            },
            onLoadError: (controller, url, code, message) {
              _hideLoader(); // Скрываем диалог при ошибке
              _showErrorDialog(message);
            },
          ),
        ],
      ),
    );
  }

  // Метод для показа загрузочного индикатора
  void _showLoader() {
    if (!isDialogVisible) {
      setState(() {
        isDialogVisible = true;
      });
      _dialog.show(
        message: 'Загрузка...',
        backgroundColor: Colors.white,
        textStyle: const TextStyle(color: Colors.black),
      );
    }
  }

  // Метод для скрытия загрузочного индикатора
  void _hideLoader() {
    if (isDialogVisible) {
      setState(() {
        isDialogVisible = false;
      });
      _dialog.hide();
    }
  }

  // Метод для отображения ошибки
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
