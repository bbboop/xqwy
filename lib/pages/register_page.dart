import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:healther/services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "选择图片失败: ${e.toString()}");
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "拍照失败: ${e.toString()}");
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _register() async {
    String name = _nameController.text;
    String phone = _phoneController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "请填写完整信息");
      return;
    }

    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: "两次输入的密码不一致");
      return;
    }

    if (_selectedImage == null) {
      Fluttertoast.showToast(msg: "请选择头像");
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

    try {
      // 调用注册API
      final result = await ApiService().register(
        name,
        phone,
        password,
        avatarFile: _selectedImage,
      );

      // 关闭加载指示器
      Navigator.pop(context);

      if (result['code'] == 200) {
        Fluttertoast.showToast(msg: "注册成功");
        Navigator.pop(context); // 返回登录页
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "注册失败");
      }
    } catch (e) {
      // 关闭加载指示器
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "注册失败: ${e.toString()}");
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isPhone = false,
    bool? obscureText,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText ?? false,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText! ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        hintText: hintText,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("创建账号"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 头像上传
                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.blue,
                              )
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
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // 姓名输入框
                _buildTextField(
                  controller: _nameController,
                  hintText: "姓名",
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                // 手机号输入框
                _buildTextField(
                  controller: _phoneController,
                  hintText: "手机号码",
                  prefixIcon: Icons.phone_android,
                  isPhone: true,
                ),
                const SizedBox(height: 16),
                // 密码输入框
                _buildTextField(
                  controller: _passwordController,
                  hintText: "设置密码",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onVisibilityToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // 确认密码输入框
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: "再次输入密码",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onVisibilityToggle: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 40),
                // 注册按钮
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "注册",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 服务条款
                Text(
                  "点击注册即表示您同意我们的服务条款和隐私政策",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
