import 'package:flutter/material.dart';
import 'package:healther/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

class FoodRecognitionPage extends StatefulWidget {
  const FoodRecognitionPage({Key? key}) : super(key: key);

  @override
  _FoodRecognitionPageState createState() => _FoodRecognitionPageState();
}

class _FoodRecognitionPageState extends State<FoodRecognitionPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _foodsList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadFoods();
      }
    }
  }

  Future<void> _loadFoods() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService().getFoodsList(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result['code'] == 200 && result['data'] != null) {
        final List<dynamic> newFoods = result['data']['list'];
        setState(() {
          _foodsList.addAll(List<Map<String, dynamic>>.from(newFoods));
          _currentPage++;
          _hasMore = newFoods.length >= _pageSize;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      Fluttertoast.showToast(msg: "加载失败：${e.toString()}");
    }
  }

  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      // 显示底部选择菜单
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('拍照'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('从相册选择'),
                  onTap: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // 检查权限
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isDenied) {
          if (!mounted) return;
          Fluttertoast.showToast(msg: "需要相机权限才能拍照");
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (status.isDenied) {
          if (!mounted) return;
          Fluttertoast.showToast(msg: "需要相册权限才能选择图片");
          return;
        }
      }

      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80, // 压缩图片质量
        maxWidth: 1920, // 限制最大宽度
        maxHeight: 1080, // 限制最大高度
      );

      if (image == null) return;

      // 显示加载对话框
      if (!mounted) return;
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

      final result = await ApiService().uploadFoodImage(File(image.path));

      // 关闭加载对话框
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['code'] == 200) {
        Fluttertoast.showToast(msg: "上传成功");
        // 重置列表并重新加载
        setState(() {
          _foodsList.clear();
          _currentPage = 1;
          _hasMore = true;
        });
        _loadFoods();
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? "上传失败");
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 确保加载对话框被关闭
      }
      Fluttertoast.showToast(msg: "上传失败：${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食物识别'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _uploadImage,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _foodsList.clear();
            _currentPage = 1;
            _hasMore = true;
          });
          await _loadFoods();
        },
        child: _foodsList.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无识别记录',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击右上角相机按钮上传图片',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _foodsList.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _foodsList.length) {
                    return _buildLoadingIndicator();
                  }

                  final food = _foodsList[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 食物图片
                        Stack(
                          children: [
                            if (food['image_path'] != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8.0),
                                ),
                                child: Image.network(
                                  food['image_path'],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.black.withValues(alpha: .5),
                                ),
                                onPressed: () => _showDeleteConfirmDialog(food),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 识别时间
                              Text(
                                "识别时间：${_formatDateTime(food['createdAt'])}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 识别结果列表
                              ...List<Widget>.from(
                                  (food['foods'] as List).map((item) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? '未知食物',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (item['calories'] != null)
                                      Text(
                                        "热量：${item['calories']} 卡路里",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    if (item['ingredients'] != null)
                                      Text(
                                        "配料：${item['ingredients']}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    const Divider(height: 24),
                                  ],
                                );
                              })),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: _hasMore
          ? const SpinKitWave(
              color: Colors.blue,
              size: 24.0,
            )
          : const Text('没有更多数据了'),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '未知时间';
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '时间格式错误';
    }
  }

  // 添加删除确认对话框方法
  Future<void> _showDeleteConfirmDialog(Map<String, dynamic> food) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条食物识别记录吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFood(food);
              },
            ),
          ],
        );
      },
    );
  }

  // 添加删除方法
  Future<void> _deleteFood(Map<String, dynamic> food) async {
    try {
      final result = await ApiService().deleteFood(food['id']);
      if (result['code'] == 200) {
        setState(() {
          _foodsList.removeWhere((item) => item['id'] == food['id']);
        });
        if (!mounted) return;
        Fluttertoast.showToast(msg: "删除成功");
      } else {
        if (!mounted) return;
        Fluttertoast.showToast(msg: result['message'] ?? "删除失败");
      }
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: "删除失败：${e.toString()}");
    }
  }
}
