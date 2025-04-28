import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healther/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  File? _avatarFile;
  String? _avatarUrl;
  bool _isLoading = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await ApiService().getUserProfile();
      if (result['code'] == 200 && result['data'] != null) {
        final userInfo = result['data'];
        if (userInfo['name'] != null) {
          _nameController.text = userInfo['name'];
        }
        if (userInfo['avatar'] != null) {
          setState(() {
            _avatarUrl = userInfo['avatar'];
          });
        }
        if (userInfo['birthdate'] != null) {
          setState(() {
            _selectedDate = DateTime.parse(userInfo['birthdate']);
          });
        }
        if (userInfo['gender'] != null) {
          setState(() {
            _selectedGender = userInfo['gender'];
          });
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
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _avatarFile = File(image.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "选择图片失败: ${e.toString()}");
    }
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: _avatarFile != null
                ? FileImage(_avatarFile!)
                : (_avatarUrl != null
                    ? NetworkImage(_avatarUrl!) as ImageProvider
                    : null),
            child: _avatarFile == null && _avatarUrl == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: InkWell(
                onTap: _pickImage,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText ?? false,
      decoration: InputDecoration(
        labelText: label,
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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText! ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: onToggleObscure,
              )
            : null,
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
        title: const Text("编辑个人信息"),
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
                      _buildAvatarPicker(),
                      const SizedBox(height: 32),
                      _buildInputField(
                        label: "昵称",
                        controller: _nameController,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: "新密码",
                        controller: _passwordController,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        label: "确认新密码",
                        controller: _confirmPasswordController,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleObscure: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
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
                            // 验证密码
                            if (_passwordController.text.isNotEmpty &&
                                _passwordController.text !=
                                    _confirmPasswordController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("两次输入的密码不一致")),
                              );
                              return;
                            }

                            if (_nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("昵称不能为空")),
                              );
                              return;
                            }

                            if (_selectedGender == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("请选择性别")),
                              );
                              return;
                            }

                            if (_selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("请选择出生日期")),
                              );
                              return;
                            }

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );

                            try {
                              final Map<String, dynamic> userData = {
                                'name': _nameController.text,
                                'gender': _selectedGender,
                                'birthdate': DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate!),
                                if (_passwordController.text.isNotEmpty)
                                  'password': _passwordController.text,
                              };

                              // 如果选择了新头像，添加到请求中
                              if (_avatarFile != null) {
                                String fileName =
                                    _avatarFile!.path.split('/').last;
                                FormData formData = FormData.fromMap({
                                  ...userData,
                                  'avatar': await MultipartFile.fromFile(
                                    _avatarFile!.path,
                                    filename: fileName,
                                  ),
                                });

                                final result =
                                    await ApiService().updateUserInfo(formData);

                                Navigator.pop(context); // 关闭加载框

                                if (result['code'] != 200) {
                                  throw Exception(result['message']);
                                }
                              } else {
                                final result =
                                    await ApiService().updateUserInfo(userData);

                                Navigator.pop(context); // 关闭加载框

                                if (result['code'] != 200) {
                                  throw Exception(result['message']);
                                }
                              }

                              Navigator.pop(context, true);
                              Fluttertoast.showToast(msg: "更新成功");
                            } catch (e) {
                              Navigator.pop(context); // 关闭加载框
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
                            "保存",
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
