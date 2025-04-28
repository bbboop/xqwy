import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:healther/services/api_service.dart';
import 'package:healther/components/bottom_navigation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_html/flutter_html.dart';
import 'register_page.dart';
import 'profile_setup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _verifyCodeController = TextEditingController();
  bool _obscureText = true;
  bool _isPasswordLogin = true;
  bool _isCountingDown = false;
  int _countDown = 60;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  void _showLoadingDialog() {
    if (!_isLoading) {
      _isLoading = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const PopScope(
            canPop: false,
            child: Center(
              child: SpinKitWave(
                color: Colors.blue,
                size: 50.0,
              ),
            ),
          );
        },
      );
    }
  }

  void _hideLoadingDialog() {
    if (_isLoading && mounted) {
      _isLoading = false;
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _startCountDown() {
    setState(() {
      _isCountingDown = true;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _countDown--;
      });
      if (_countDown == 0) {
        setState(() {
          _isCountingDown = false;
          _countDown = 60;
        });
        return false;
      }
      return true;
    });
  }

  void _sendVerifyCode() async {
    if (_phoneController.text.isEmpty) {
      Fluttertoast.showToast(msg: "请输入手机号");
      return;
    }
    if (_phoneController.text.length != 11) {
      Fluttertoast.showToast(msg: "请输入正确的手机号");
      return;
    }

    final result = await ApiService().sendSmsCode(_phoneController.text);
    if (result['code'] == 200) {
      Fluttertoast.showToast(msg: "验证码已发送");
      _startCountDown();
    } else {
      Fluttertoast.showToast(msg: result['message'] ?? "发送验证码失败");
    }
  }

  Future<void> _showAgreementDialog(String title, String content) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Html(data: content),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTerms() async {
    try {
      final response = await ApiService().getTermsOfService();
      if (response['code'] == 200 && mounted) {
        await _showAgreementDialog('用户协议', response['data']['content']);
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? '获取用户协议失败');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '获取用户协议失败');
    }
  }

  Future<void> _showPrivacy() async {
    try {
      final response = await ApiService().getPrivacyPolicy();
      if (response['code'] == 200 && mounted) {
        await _showAgreementDialog('隐私政策', response['data']['content']);
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? '获取隐私政策失败');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '获取隐私政策失败');
    }
  }

  Future<bool> _confirmAgreement() async {
    if (!_agreedToTerms) {
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('提示'),
            content: const Text('请阅读并同意用户协议和隐私政策'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _agreedToTerms = true;
                  });
                  Navigator.of(context).pop(true);
                },
                child: const Text('同意'),
              ),
            ],
          );
        },
      );
      return result ?? false;
    }
    return true;
  }

  void _login() async {
    if (!await _confirmAgreement()) {
      return;
    }

    if (_isPasswordLogin) {
      String phone = _usernameController.text;
      String password = _passwordController.text;

      if (phone.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(msg: "手机号和密码不能为空");
        return;
      }

      _showLoadingDialog();

      try {
        final result = await ApiService().loginWithPassword(phone, password);
        _hideLoadingDialog();

        if (result['code'] == 200) {
          Fluttertoast.showToast(msg: "登录成功");

          // 检查用户资料是否完整
          final isProfileComplete = await ApiService().isProfileComplete();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => isProfileComplete
                    ? const BottomNavigation()
                    : const ProfileSetupPage(),
              ),
            );
          }
        } else {
          Fluttertoast.showToast(
              msg: result['message'] ?? "登录失败", gravity: ToastGravity.CENTER);
        }
      } catch (e) {
        _hideLoadingDialog();
        Fluttertoast.showToast(msg: "登录失败: ${e.toString()}");
      }
    } else {
      String phone = _phoneController.text;
      String code = _verifyCodeController.text;

      if (phone.isEmpty) {
        Fluttertoast.showToast(msg: "请输入手机号");
        return;
      }
      if (code.isEmpty) {
        Fluttertoast.showToast(msg: "请输入验证码");
        return;
      }

      _showLoadingDialog();

      try {
        final result = await ApiService().loginWithSms(phone, code);
        _hideLoadingDialog();

        if (result['code'] == 200) {
          Fluttertoast.showToast(msg: "登录成功");

          // 检查用户资料是否完整
          final isProfileComplete = await ApiService().isProfileComplete();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => isProfileComplete
                    ? const BottomNavigation()
                    : const ProfileSetupPage(),
              ),
            );
          }
        } else {
          Fluttertoast.showToast(msg: result['message'] ?? "登录失败");
        }
      } catch (e) {
        _hideLoadingDialog();
        Fluttertoast.showToast(msg: "登录失败: ${e.toString()}");
      }
    }
  }

  Widget _buildPasswordLogin() {
    return Column(
      children: [
        TextField(
          controller: _usernameController,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          textInputAction: TextInputAction.done,
          maxLength: 11,
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
          onSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: "",
            prefixIcon: const Icon(Icons.person_outline),
            hintText: "手机号",
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            hintText: "密码",
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyCodeLogin() {
    return Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          textInputAction: TextInputAction.done,
          maxLength: 11,
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
          onSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: "",
            prefixIcon: const Icon(Icons.phone_android),
            hintText: "请输入手机号",
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _verifyCodeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          textInputAction: TextInputAction.done,
          maxLength: 6,
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
          onSubmitted: (value) {
            FocusScope.of(context).unfocus();
          },
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: "",
            prefixIcon: const Icon(Icons.lock_outline),
            hintText: "请输入验证码",
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1),
            ),
            suffixIcon: TextButton(
              onPressed: _isCountingDown ? null : _sendVerifyCode,
              child: Text(
                _isCountingDown ? "$_countDown秒后重试" : "获取验证码",
                style: TextStyle(
                  color: _isCountingDown ? Colors.grey : Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/icon/icon.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 标题
                  const Text(
                    "身体数据管理",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // 登录表单
                  _isPasswordLogin
                      ? _buildPasswordLogin()
                      : _buildVerifyCodeLogin(),
                  const SizedBox(height: 12),
                  // 切换登录方式
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordLogin = !_isPasswordLogin;
                        });
                      },
                      child: Text(
                        _isPasswordLogin ? "使用验证码登录" : "使用密码登录",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 登录按钮
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "登录",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 注册按钮
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "注册",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Third-party login section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.wechat,
                            color: Color(0xFF07C160),
                            size: 28,
                          ),
                          onPressed: () {
                            // TODO: 实现微信登录
                          },
                        ),
                      ),
                    ],
                  ),
                  // Add agreement section before third-party login
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(50), // Makes it circular
                        ),
                        value: _agreedToTerms,
                        onChanged: (bool? value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        side: const BorderSide(color: Colors.black54), // 边框样式
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text(
                              '我已阅读并同意',
                              style: TextStyle(color: Colors.black54),
                            ),
                            GestureDetector(
                              onTap: _showTerms,
                              child: const Text(
                                '《用户协议》',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                            const Text(
                              '和',
                              style: TextStyle(color: Colors.black54),
                            ),
                            GestureDetector(
                              onTap: _showPrivacy,
                              child: const Text(
                                '《隐私政策》',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _verifyCodeController.dispose();
    super.dispose();
  }
}
