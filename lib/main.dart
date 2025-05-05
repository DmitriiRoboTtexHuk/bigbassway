import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

void main() async {
  FCMTokenListener.listenForTokenUpdates;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}
class FCMTokenListener {
  static const MethodChannel _channel = MethodChannel('com.example.fcm/token');

  /// Listener for FCM token updates
  static void listenForTokenUpdates(Function(String token) onTokenUpdated) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String token = call.arguments as String;
        onTokenUpdated(token);
        print('FCM Token received in Flutter: $token');
      }
    });
  }
}
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LaunchInitializer(),
    );
  }
}

class LaunchInitializer extends StatefulWidget {
  @override
  State<LaunchInitializer> createState() => _LaunchInitializerState();
}

class _LaunchInitializerState extends State<LaunchInitializer> {
  String? deviceType;
  String? systemVersion;
  String? pushToken;
  String? localeCode;
  String? localTimezone;
  String? uniqueDeviceId;
  String? appsFlyerUid;
  String? adId;
  String? urlParameters;
  String? finalWebUrl;
  bool isLoading = true;
  String serverResponse = "";
  late AppsflyerSdk appsFlyerInstance;
  String bundle="com.wwwe.basswaybigbass";

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    initializeEverything();

    FCMTokenListener.listenForTokenUpdates((token) {
      setState(() {
        pushToken = token;
      });
    });
  }

  Future<void> initializeEverything() async {
    await initializeAppsFlyer();
    await retrievePushToken();
    await performServerRequest();

    String webUrl = "https://bass-way-big-bass.online/bwbb/";
    if (urlParameters != null && urlParameters!.isNotEmpty) {
      webUrl += "?$urlParameters";
    }

    setState(() {
      finalWebUrl = webUrl;
      isLoading = false;
    });
  }

  Future<void> initializeAppsFlyer() async {
    AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "P8Cmc5f5JjkNjQ3haoGbWS",
      appId: "6745129171",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 0,
    );
    appsFlyerInstance = AppsflyerSdk(options);

    await appsFlyerInstance.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
  }

  Future<void> retrievePushToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        pushToken = token;
      });
    } catch (e) {
      // Ignore push token error
    }
  }

  Future<void> performServerRequest() async {
    // Get AppsFlyer UID
    appsFlyerUid = await appsFlyerInstance.getAppsFlyerUID();

    // Get device info
    final devicePlugin = DeviceInfoPlugin();
    final iosDevice = await devicePlugin.iosInfo;
    deviceType = iosDevice.utsname.machine;
    systemVersion = iosDevice.systemVersion;
    localeCode = 'rus';
    localTimezone = DateTime.now().timeZoneName;
    uniqueDeviceId = iosDevice.identifierForVendor;

    setState(() {
      urlParameters = "device_model=${deviceType ?? ""}"
          "&os_version=${systemVersion ?? ""}"
          "&fcm_token=${pushToken ?? ""}"
          "&language=${localeCode ?? ""}"
          "&timezone=${localTimezone ?? ""}"
          "&apps_flyer_id=${appsFlyerUid ?? ""}"
          "&advertising_id=${adId ?? ""}"
          "&bundle=${bundle ?? ""}"
          "&device_id=${uniqueDeviceId ?? ""}";
    });

    String endpointUrl = "https://bass-way-big-bass.online/bwbb/plkz1/index.php"
        "?device_model=${deviceType ?? ""}"
        "&os_version=${systemVersion ?? ""}"
        "&fcm_token=${pushToken ?? ""}"
        "&language=${localeCode ?? ""}"
        "&timezone=${localTimezone ?? ""}"
        "&apps_flyer_id=${appsFlyerUid ?? ""}"
        "&bundle=${bundle ?? ""}"
        "&advertising_id=${adId ?? ""}"
        "&device_id=${uniqueDeviceId ?? ""}";

    print("REQUEST URL: $endpointUrl");
    final uri = Uri.parse(endpointUrl);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          serverResponse = "Success: ${response.body}";
          print("SERVER OK"+ serverResponse );
        });
      } else {
        setState(() {
          serverResponse = "Error: ${response.statusCode} - ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        serverResponse = "Request failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || finalWebUrl == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return CustomWebView(finalWebUrl!, urlParameters: urlParameters);;
  }
}

class CustomWebView extends StatefulWidget {
  final String url;
  final String? urlParameters;
  const CustomWebView(this.url, {this.urlParameters, Key? key}) : super(key: key);

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView>
    with SingleTickerProviderStateMixin {
  late AnimationController loaderAnimation;
  bool dialogShowing = false;

  @override
  void initState() {
    super.initState();
    loaderAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    loaderAnimation.dispose();
    super.dispose();
  }

  void showLoader() {
    if (!dialogShowing) {
      setState(() {
        dialogShowing = true;
      });
    }
  }

  void hideLoader() {
    if (dialogShowing) {
      setState(() {
        dialogShowing = false;
      });
    }
  }

  void showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.url),
            ),
            onWebViewCreated: (controller) async {
              String jsParam = widget.urlParameters ?? "";
              print("PARAM "+widget.urlParameters .toString());
              String javaScriptCode = """
    fetch('https://bass-way-big-bass.online/bwbb/plkz1/index.php?$jsParam')
      .then(response => response.text())
      .then(data => {
          console.log('Data:', data);
          document.body.innerHTML += '<p>Ответ сервера: ' + data + '</p>';
      })
      .catch(error => {
          console.error('Error:', error);
          document.body.innerHTML += '<p>Ошибка: ' + error + '</p>';
      });
  """;
              try {
                await controller.evaluateJavascript(source: javaScriptCode);
                print("JavaScript выполнен успешно");
              } catch (error) {
                print("Ошибка выполнения JavaScript: $error");
              }
            },
            onLoadStart: (controller, url) {
              showLoader();
            },
            onLoadStop: (controller, url) async {
              hideLoader();
            },
            onLoadError: (controller, url, code, message) {
              hideLoader();
              showErrorDialog(message);
            },
          ),
          if (dialogShowing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: loaderAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -loaderAnimation.value * 50),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.elevator,
                              size: 50,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}