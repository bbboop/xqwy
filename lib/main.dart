import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:healther/components/bottom_navigation.dart';
import 'package:healther/pages/login_page.dart';
import 'package:healther/pages/splash_screen.dart';
import 'package:healther/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upgrader/upgrader.dart';
import 'package:provider/provider.dart';
import 'package:healther/providers/health_sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 请求网络权限
  await Permission.notification.request();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 只允许竖屏向上
    DeviceOrientation.portraitDown, // 只允许竖屏向下
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthSyncProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 全局导航键，用于在任何地方导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();

    // 设置 token 过期回调函数
    ApiService.onTokenExpired = _handleTokenExpired;
  }

  Future<void> _initializeApp() async {
    // 并行执行初始化任务
    await Future.wait([
      _checkLoginStatus(),
    ]);
  }

  // 处理 token 过期
  void _handleTokenExpired() {
    setState(() {
      _isLoggedIn = false;
    });

    // 使用全局导航键跳转到登录页
    if (navigatorKey.currentState != null) {
      // 弹出提示对话框
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('登录已过期'),
          content: const Text('您的登录状态已过期，请重新登录'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                // 清除导航栈，跳转到登录页
                navigatorKey.currentState!.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      setState(() {
        _isLoggedIn = true;
        // 先设置为已登录，但保持加载状态
      });

      // 登录状态有效，获取用户信息
      try {
        final result = await ApiService().getUserProfile();
        if (result['code'] == 200) {
          // 已经成功获取用户信息，检查资料是否完整
          setState(() {
            _isLoading = false;
          });
        } else if (result['code'] == 401) {
          // token 已过期，清除登录状态
          await ApiService().clearToken();
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
        } else {
          // 其他错误，保持登录状态，结束加载
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        // 请求失败，但保持登录状态
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '喜鹊无忧',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
        fontFamily: "PingFang SC",
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN')],
      home: UpgradeAlert(
        upgrader: Upgrader(
          languageCode: 'zh',
          messages: UpgraderMessages(code: 'zh'),
          durationUntilAlertAgain: const Duration(days: 1),
        ),
        child: _isLoading
            ? const SplashScreen()
            : _isLoggedIn
                ? const BottomNavigation()
                : const LoginPage(),
      ),
    );
  }
}
