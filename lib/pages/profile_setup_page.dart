import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healther/components/bottom_navigation.dart';
import 'package:healther/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // 获取用户信息
      final result = await ApiService().getUserProfile();
      if (result['code'] == 200 && result['data'] != null) {
        final userInfo = result['data'];

        // 检查是否所有必要的个人信息都已填写
        bool isProfileComplete = userInfo['height'] != null &&
            userInfo['weight'] != null &&
            userInfo['birthdate'] != null &&
            userInfo['gender'] != null;

        if (isProfileComplete) {
          // 如果个人信息已完整，直接跳转到首页
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BottomNavigation(),
              ),
            );
          }
          return;
        }

        // 如果信息不完整，预填充现有的数据
        if (userInfo['height'] != null) {
          _heightController.text = userInfo['height'].toString();
        }
        if (userInfo['weight'] != null) {
          _weightController.text = userInfo['weight'].toString();
        }
        if (userInfo['birthdate'] != null) {
          _selectedDate = DateTime.parse(userInfo['birthdate']);
        }
        if (userInfo['gender'] != null) {
          _selectedGender = userInfo['gender'];
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "获取用户信息失败: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // 默认18岁
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // 头部背景色
              onPrimary: Colors.white, // 头部文字颜色
              onSurface: Colors.black, // 日历文字颜色
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.number,
      inputFormatters:
          inputFormatters ?? [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
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
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null
                  ? "出生日期"
                  : "${_selectedDate!.year}年${_selectedDate!.month}月${_selectedDate!.day}日",
              style: TextStyle(
                color:
                    _selectedDate == null ? Colors.grey[600] : Colors.black87,
                fontSize: 16,
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("性别"),
          value: _selectedGender,
          items: const [
            DropdownMenuItem(value: "男", child: Text("男")),
            DropdownMenuItem(value: "女", child: Text("女")),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("完善个人信息"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          "欢迎使用身体数据管理",
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "请填写您的基本身体信息，帮助我们为您提供\n更准确的健康建议",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildInputField(
                        label: "身高",
                        controller: _heightController,
                        suffix: "cm",
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: "体重",
                        controller: _weightController,
                        suffix: "kg",
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(),
                      const SizedBox(height: 16),
                      _buildGenderField(),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_heightController.text.isEmpty ||
                                _weightController.text.isEmpty ||
                                _selectedDate == null ||
                                _selectedGender == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("请填写完整信息")),
                              );
                              return;
                            }

                            // 显示加载指示器
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );

                            DateFormat formatter = DateFormat('yyyy-MM-dd');
                            try {
                              // 构建用户资料数据
                              final Map<String, dynamic> profileData = {
                                'height': double.parse(_heightController.text),
                                'weight': double.parse(_weightController.text),
                                'birthdate': formatter.format(_selectedDate!),
                                'gender': _selectedGender,
                              };

                              // 调用 API 更新服务器用户资料
                              final result = await ApiService()
                                  .updateUserProfile(profileData);

                              // 关闭加载指示器
                              Navigator.pop(context);

                              if (result['code'] != 200) {
                                Fluttertoast.showToast(
                                    msg: result['message'] ?? "更新资料失败");
                                return;
                              }

                              // 保存个人信息并跳转到首页
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BottomNavigation(),
                                ),
                              );
                            } catch (e) {
                              // 关闭加载指示器
                              Navigator.pop(context);
                              Fluttertoast.showToast(
                                  msg: "保存失败: ${e.toString()}");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "保存并继续",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
