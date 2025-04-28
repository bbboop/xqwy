import 'package:flutter/material.dart';
import 'package:healther/pages/profile_edit_page.dart';
import 'package:healther/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:healther/pages/login_page.dart';
import 'package:healther/pages/feedback_page.dart';
import 'package:healther/pages/privacy_policy_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _userInfo = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService().getUserProfile();
      if (result['code'] == 200 && result['data'] != null) {
        setState(() {
          _userInfo = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? '获取用户信息失败';
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: _errorMessage);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '获取用户信息失败: ${e.toString()}';
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: _errorMessage);
    }
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // 显示加载指示器
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              await ApiService().logout();

              // 关闭加载指示器
              Navigator.pop(context);

              // 清除导航栈，跳转到登录页
              Navigator.of(context).pushAndRemoveUntil(
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

  Widget _buildUserInfo() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final name = _userInfo['name'] ?? '未设置姓名';
    final height =
        _userInfo['height'] != null ? '${_userInfo['height']}cm' : '';
    final weight =
        _userInfo['weight'] != null ? '${_userInfo['weight']}kg' : '';

    // 获取性别信息
    String gender = '';
    if (_userInfo['gender'] != null) {
      if (_userInfo['gender'] == 'male') {
        gender = '男';
      } else if (_userInfo['gender'] == 'female') {
        gender = '女';
      }
    }

    // 如果有生日信息，计算年龄
    String age = '';
    if (_userInfo['birthdate'] != null) {
      try {
        final birthDate = DateTime.parse(_userInfo['birthdate']);
        final currentDate = DateTime.now();
        int years = currentDate.year - birthDate.year;
        if (currentDate.month < birthDate.month ||
            (currentDate.month == birthDate.month &&
                currentDate.day < birthDate.day)) {
          years--;
        }
        age = '$years岁';
      } catch (e) {
        // 解析日期出错，忽略年龄显示
      }
    }

    // 构建资料字符串
    final List<String> profileParts = [];
    if (height.isNotEmpty) profileParts.add(height);
    if (weight.isNotEmpty) profileParts.add(weight);
    if (gender.isNotEmpty) profileParts.add(gender);
    if (age.isNotEmpty) profileParts.add(age);

    final profileText =
        profileParts.isEmpty ? '点击编辑完善资料' : profileParts.join(' · ');

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: _userInfo['avatar'] != null &&
                    _userInfo['avatar'].toString().isNotEmpty
                ? _getAvatarImage(_userInfo['avatar'])
                : const AssetImage('assets/images/avatar.png') as ImageProvider,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            profileText,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditPage(),
                ),
              );
              if (result == true) {
                // 如果返回 true，表示资料已更新，重新加载用户信息
                _loadUserInfo();
              }
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('编辑资料'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('个人中心'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildUserInfo(),
              // _buildSettingItem(
              //   icon: Icons.settings,
              //   title: '通用设置',
              //   iconColor: Colors.grey,
              //   onTap: () {
              //     Fluttertoast.showToast(msg: "通用设置功能待实现");
              //   },
              // ),
              // _buildSettingItem(
              //   icon: Icons.notifications,
              //   title: '提醒设置',
              //   iconColor: Colors.blue,
              //   onTap: () {
              //     Fluttertoast.showToast(msg: "提醒设置功能待实现");
              //   },
              // ),
              // _buildSettingItem(
              //   icon: Icons.health_and_safety,
              //   title: '编辑基础数据',
              //   iconColor: Colors.red,
              //   onTap: () async {
              //     final result = await Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => const HealthEditPage(),
              //       ),
              //     );
              //     if (result == true) {
              //       // 如果返回true，表示数据已更新，可以在这里添加刷新逻辑
              //       Fluttertoast.showToast(msg: '健康数据已更新');
              //     }
              //   },
              // ),
              _buildSettingItem(
                icon: Icons.security,
                title: '隐私与安全',
                iconColor: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.help_outline,
                title: '帮助与反馈',
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 获取头像图像的方法
  ImageProvider _getAvatarImage(String avatar) {
    // 检查是否已经是完整的 URL
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    } else {
      // 将相对路径转为完整 URL
      // 这里假设 API 服务器基础 URL 与接口相同
      String baseUrl = ApiService().getBaseUrl();
      // 确保不会重复斜杠
      if (baseUrl.endsWith('/') && avatar.startsWith('/')) {
        return NetworkImage('$baseUrl${avatar.substring(1)}');
      } else if (!baseUrl.endsWith('/') && !avatar.startsWith('/')) {
        return NetworkImage('$baseUrl/$avatar');
      } else {
        return NetworkImage('$baseUrl$avatar');
      }
    }
  }
}
