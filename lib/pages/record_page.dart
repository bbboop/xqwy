import 'package:flutter/material.dart';
import 'package:healther/components/body_model.dart';
import 'package:healther/pages/health_analysis_page.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:healther/services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:healther/providers/health_sync_provider.dart';
import 'package:healther/services/health_service.dart';

class _EditIconAnimation extends StatefulWidget {
  final Color color;
  final bool isSelected;

  const _EditIconAnimation({
    required this.color,
    required this.isSelected,
  });

  @override
  State<_EditIconAnimation> createState() => _EditIconAnimationState();
}

class _EditIconAnimationState extends State<_EditIconAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_animation.value * 0.2),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Icon(
        Icons.edit,
        size: 14,
        color: widget.isSelected
            ? widget.color.withValues(alpha: .6)
            : Colors.grey[400],
      ),
    );
  }
}

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final logger = Logger();
  final Map<String, bool> _selectedTypes = {
    'weight': false,
    'heart': false,
    'blood_pressure': false,
    'blood_sugar': false,
    'sleep': false,
    'exercise': false,
    'body_overview': true,
  };

  final bool _isMale = true;
  bool _isSyncing = false;
  bool _showData = false;

  // 健康数据
  Map<String, dynamic> _processedData = {};

  // 创建健康服务实例
  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    // 加载显示设置
    _loadDisplaySettings();
    // 获取数据
    _fetchAndUpdateHealthData();
    // 页面加载时自动同步数据
    _syncHealthData(0);
  }

  // 加载显示设置
  Future<void> _loadDisplaySettings() async {
    try {
      final response = await ApiService().getDataDisplaySettings();
      if (response['code'] == 200 && response['data'] != null) {
        setState(() {
          final settings = response['data']['settings'];
          _selectedTypes['weight'] = settings['weight'] ?? true;
          _selectedTypes['heart'] = settings['heart'] ?? true;
          _selectedTypes['blood_pressure'] = settings['blood_pressure'] ?? true;
          _selectedTypes['blood_sugar'] = settings['blood_sugar'] ?? true;
          _selectedTypes['sleep'] = settings['sleep'] ?? true;
          _selectedTypes['exercise'] = settings['exercise'] ?? true;
          _selectedTypes['body_overview'] = settings['body_overview'] ?? true;
          _showData = settings['body_overview'] ?? true;
        });
      }
    } catch (e) {
      logger.d('加载显示设置失败: $e');
    }
  }

  // 保存显示设置
  Future<void> _saveDisplaySettings() async {
    try {
      final response =
          await ApiService().saveDataDisplaySettings(_selectedTypes);
      if (response['code'] != 200) {
        logger.d('保存显示设置失败: ${response['message']}');
      }
    } catch (e) {
      logger.d('保存显示设置失败: $e');
    }
  }

  // 从苹果健康获取数据的统一方法
  Future<void> _fetchAndUpdateHealthData() async {
    try {
      // 获取健康数据
      final healthData = await _healthService.fetchHealthData();
      // 处理健康数据
      final processedData = await _healthService.processHealthData(healthData);

      if (mounted) {
        setState(() {
          _processedData = processedData;
        });
      }
      return;
    } catch (e) {
      logger.d('获取健康数据失败: $e');
      Fluttertoast.showToast(msg: "获取健康数据失败");
    }
  }

  // 同步苹果健康数据
  Future<void> _syncHealthData(type) async {
    if (_isSyncing) return;

    // 如果是自动同步（type == 0）且本次会话已经同步过，则跳过
    if (type == 0 && context.read<HealthSyncProvider>().hasSyncedThisSession) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      // 请求健康数据权限
      bool authorized = await _healthService.requestHealthPermission();
      if (!authorized) {
        if (mounted) {
          setState(() {
            _isSyncing = false;
          });
          Fluttertoast.showToast(
              msg: "请在iPhone的设置-隐私与安全性-健康中允许本应用访问健康数据，并确保所有需要的数据类型都已开启。");
          return;
        }
      }

      // 获取并更新健康数据
      await _fetchAndUpdateHealthData();

      // 更新全局同步状态
      context.read<HealthSyncProvider>().setHasSyncedThisSession(true);

      // 显示同步成功提示
      Fluttertoast.showToast(msg: "数据同步成功");

      // 上传健康数据到服务器
      final success = await _healthService.uploadHealthData(_processedData);
      if (!success) {
        logger.d('上传健康数据失败');
      }

      setState(() {
        _isSyncing = false;
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      Fluttertoast.showToast(msg: "数据同步失败");
    }
  }

  void _handleBodyPartTap(String part) {
    String type;
    switch (part) {
      case 'head':
        type = 'sleep';
        break;
      case 'heart':
        type = 'heart';
        break;
      case 'arm':
        type = 'blood_pressure';
        break;
      case 'abdomen':
        type = 'blood_sugar';
        break;
      case 'legs':
        type = 'exercise';
        break;
      case 'weight':
        type = 'weight';
        break;
      default:
        return;
    }
    setState(() {
      _selectedTypes[type] = !_selectedTypes[type]!;
    });
    // 保存设置
    _saveDisplaySettings();
  }

  Widget _buildSyncCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "记录数据",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthAnalysisPage(),
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology, color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _syncHealthData(1),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: _isSyncing
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          )
                        : const Icon(Icons.sync, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSyncing ? "正在同步..." : "同步健康数据",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "从iOS健康应用导入您的健康数据",
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: _buildDataTypes()),
        ],
      ),
    );
  }

  List<Widget> _buildDataTypes() {
    final List<Map<String, dynamic>> dataTypes = [
      {
        'title': '体重',
        'icon': Icons.monitor_weight,
        'color': Colors.blue,
        'backgroundColor': Colors.blue.shade50,
        'type': 'weight',
      },
      {
        'title': '心率',
        'icon': Icons.favorite,
        'color': Colors.red,
        'backgroundColor': Colors.red.shade50,
        'type': 'heart',
      },
      {
        'title': '血压',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'backgroundColor': Colors.blue.shade50,
        'type': 'blood_pressure',
      },
      {
        'title': '血糖',
        'icon': Icons.bloodtype,
        'color': Colors.purple,
        'backgroundColor': Colors.purple.shade50,
        'type': 'blood_sugar',
      },
      {
        'title': '睡眠',
        'icon': Icons.nightlight_round,
        'color': Colors.orange,
        'backgroundColor': Colors.orange.shade50,
        'type': 'sleep',
      },
      {
        'title': '运动',
        'icon': Icons.directions_run,
        'color': Colors.green,
        'backgroundColor': Colors.green.shade50,
        'type': 'exercise',
      },
    ];

    return dataTypes.map((type) {
      final isSelected = _selectedTypes[type['type']] ?? true;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedTypes[type['type']] = !isSelected;
          });
          // 保存设置
          _saveDisplaySettings();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? type['backgroundColor'] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type['icon'],
                size: 16,
                color: isSelected ? type['color'] : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                type['title'],
                style: TextStyle(
                  color: isSelected ? type['color'] : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDataTypeGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "身体数据概览",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () async {
                  setState(() {
                    _showData = !_showData;
                    _selectedTypes['body_overview'] = _showData;
                  });
                  // 保存设置
                  await _saveDisplaySettings();
                },
                icon: Icon(
                  _showData ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: Colors.grey[600],
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: _showData ? "隐藏数据" : "显示数据",
              ),
              const Spacer(),
              Text(
                "近7日平均数据",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 400,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: BodyModel(
                    onPartTap: _handleBodyPartTap,
                    isMale: _isMale,
                    selectedTypes: _selectedTypes,
                  ),
                ),
                if (_showData) ...[
                  // 根据状态显示/隐藏数据
                  // 左侧数据
                  Positioned(
                    left: 0,
                    top: 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: _selectedTypes['sleep'] ?? true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataBox(
                                "睡眠",
                                _processedData['average_sleep_hours'] ?? "-",
                                "小时",
                                Colors.orange,
                                _selectedTypes['sleep'] ?? false,
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _selectedTypes['blood_pressure'] ?? true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: _buildDataBox(
                            "血压",
                            "${_processedData['latest_systolic'] ?? "-"}/${_processedData['latest_diastolic'] ?? "-"}",
                            "mmHg",
                            Colors.blue,
                            _selectedTypes['blood_pressure'] ?? false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右侧数据
                  Positioned(
                    right: 0,
                    top: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Visibility(
                          visible: _selectedTypes['heart'] ?? true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildDataBox(
                                "心率",
                                _processedData['latest_heart_rate'] ?? "-",
                                "次/分",
                                Colors.red,
                                _selectedTypes['heart'] ?? false,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _selectedTypes['blood_sugar'] ?? true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: _buildDataBox(
                            "血糖",
                            _processedData['latest_glucose'] ?? "-",
                            "mmol/L",
                            Colors.purple,
                            _selectedTypes['blood_sugar'] ?? false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 底部数据
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Visibility(
                          visible: _selectedTypes['weight'] ?? true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: _buildDataBox(
                            "体重",
                            _processedData['latest_weight'] ?? "-",
                            "kg",
                            Colors.blue,
                            _selectedTypes['weight'] ?? false,
                          ),
                        ),
                        Visibility(
                          visible: _selectedTypes['exercise'] ?? true,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: _buildDataBox(
                            "步数",
                            _processedData['average_daily_steps'] ?? "-",
                            "步",
                            Colors.green,
                            _selectedTypes['exercise'] ?? false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataBox(
      String title, String value, String unit, Color color, bool isSelected) {
    bool isEmpty;
    if (title == "血压") {
      isEmpty = value == "-" || value == "-/-";
    } else {
      isEmpty = value == "-";
    }

    return GestureDetector(
      onTap: () => _showInputDialog(title, value, unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isEmpty
                  ? color.withValues(alpha: .05)
                  : color.withValues(alpha: .1))
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isEmpty ? color.withValues(alpha: .3) : color)
                : Colors.grey[300]!,
            width: isEmpty ? 2 : 1,
            style: isEmpty ? BorderStyle.none : BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isEmpty) ...[
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: isSelected ? color : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                "点击输入",
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? color : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? color : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              _EditIconAnimation(
                color: color,
                isSelected: isSelected,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showInputDialog(
      String title, String currentValue, String unit) async {
    TextEditingController systolicController = TextEditingController();
    TextEditingController diastolicController = TextEditingController();
    TextEditingController valueController = TextEditingController();
    TextEditingController sleepStartController = TextEditingController();
    TextEditingController sleepEndController = TextEditingController();

    if (title != "血压" && title != "睡眠") {
      valueController.text = currentValue != "-" ? currentValue : "";
    } else if (title == "血压") {
      final values = currentValue.split("/");
      if (values.length == 2 && values[0] != "-") {
        systolicController.text = values[0];
        diastolicController.text = values[1];
      }
    }

    final inputDecoration = InputDecoration(
      labelText: title,
      suffixText: unit,
      hintText: "请输入$title数值",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                currentValue == "-" ? Icons.add_circle_outline : Icons.edit,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "${currentValue == "-" ? "添加" : "添加"}$title",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildInputContent(
              title,
              inputDecoration,
              valueController,
              systolicController,
              diastolicController,
              sleepStartController,
              sleepEndController,
              currentValue == "-",
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "取消",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      try {
                        // 首先检查权限
                        bool authorized =
                            await _healthService.requestHealthPermission();
                        if (!authorized) {
                          Fluttertoast.showToast(msg: "需要健康数据权限");
                          return;
                        }

                        bool writeSuccess = false;
                        switch (title) {
                          case "血压":
                            if (systolicController.text.isNotEmpty &&
                                diastolicController.text.isNotEmpty) {
                              writeSuccess =
                                  await _healthService.writeBloodPressure(
                                int.parse(systolicController.text),
                                int.parse(diastolicController.text),
                              );
                            }
                            break;
                          case "体重":
                            if (valueController.text.isNotEmpty) {
                              writeSuccess = await _healthService.writeWeight(
                                  double.parse(valueController.text));
                            }
                            break;
                          case "心率":
                            if (valueController.text.isNotEmpty) {
                              writeSuccess =
                                  await _healthService.writeHeartRate(
                                      int.parse(valueController.text));
                            }
                            break;
                          case "血糖":
                            if (valueController.text.isNotEmpty) {
                              writeSuccess =
                                  await _healthService.writeBloodGlucose(
                                      double.parse(valueController.text));
                            }
                            break;
                          case "步数":
                            if (valueController.text.isNotEmpty) {
                              writeSuccess = await _healthService
                                  .writeSteps(int.parse(valueController.text));
                            }
                            break;
                          case "睡眠":
                            if (sleepStartController.text.isNotEmpty &&
                                sleepEndController.text.isNotEmpty) {
                              final now = DateTime.now();
                              final yesterday =
                                  now.subtract(const Duration(days: 1));
                              final startHour = int.parse(
                                  sleepStartController.text.split(':')[0]);
                              final startMinute = int.parse(
                                  sleepStartController.text.split(':')[1]);
                              final endHour = int.parse(
                                  sleepEndController.text.split(':')[0]);
                              final endMinute = int.parse(
                                  sleepEndController.text.split(':')[1]);

                              // 创建开始时间（使用昨天的日期）
                              DateTime startTime = DateTime(
                                yesterday.year,
                                yesterday.month,
                                yesterday.day,
                                startHour,
                                startMinute,
                              );

                              // 创建结束时间（使用今天的日期）
                              DateTime endTime = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                endHour,
                                endMinute,
                              );

                              writeSuccess = await _healthService.writeSleep(
                                  startTime, endTime);
                            }
                            break;
                        }

                        if (writeSuccess) {
                          // 关闭对话框
                          Navigator.pop(context);
                          // 显示成功提示
                          Fluttertoast.showToast(msg: "数据写入成功");
                          // 重新获取数据更新界面
                          await _fetchAndUpdateHealthData();
                        } else {
                          Fluttertoast.showToast(msg: "数据写入失败，请检查权限设置");
                        }
                      } catch (e) {
                        logger.d('写入健康数据失败: $e');
                        Fluttertoast.showToast(msg: "数据写入失败，请检查输入格式");
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "确定",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );
  }

  Widget _buildInputContent(
    String title,
    InputDecoration inputDecoration,
    TextEditingController valueController,
    TextEditingController systolicController,
    TextEditingController diastolicController,
    TextEditingController sleepStartController,
    TextEditingController sleepEndController,
    bool autofocus,
  ) {
    switch (title) {
      case "血压":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: systolicController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration.copyWith(
                labelText: "收缩压",
                suffixText: "mmHg",
                hintText: "请输入收缩压数值",
              ),
              autofocus: autofocus,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: diastolicController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration.copyWith(
                labelText: "舒张压",
                suffixText: "mmHg",
                hintText: "请输入舒张压数值",
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case "睡眠":
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () async {
                TimeOfDay? selectedTime = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 22, minute: 0),
                  helpText: "选择入睡时间",
                  cancelText: "取消",
                  confirmText: "确定",
                  hourLabelText: "时",
                  minuteLabelText: "分",
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        timePickerTheme: TimePickerThemeData(
                          backgroundColor: Colors.white,
                          hourMinuteShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          dayPeriodShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          dayPeriodColor: Colors.blue.shade50,
                          dayPeriodTextColor: Colors.blue,
                          dayPeriodBorderSide:
                              const BorderSide(color: Colors.transparent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (selectedTime != null) {
                  sleepStartController.text =
                      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
                }
              },
              child: IgnorePointer(
                child: TextField(
                  controller: sleepStartController,
                  decoration: inputDecoration.copyWith(
                    labelText: "入睡时间",
                    hintText: "点击选择入睡时间",
                    suffixIcon:
                        const Icon(Icons.access_time, color: Colors.blue),
                    suffixText: null,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                TimeOfDay? selectedTime = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 7, minute: 0),
                  helpText: "选择起床时间",
                  cancelText: "取消",
                  confirmText: "确定",
                  hourLabelText: "时",
                  minuteLabelText: "分",
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        timePickerTheme: TimePickerThemeData(
                          backgroundColor: Colors.white,
                          hourMinuteShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          dayPeriodShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          dayPeriodColor: Colors.blue.shade50,
                          dayPeriodTextColor: Colors.blue,
                          dayPeriodBorderSide:
                              const BorderSide(color: Colors.transparent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (selectedTime != null) {
                  sleepEndController.text =
                      "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
                }
              },
              child: IgnorePointer(
                child: TextField(
                  controller: sleepEndController,
                  decoration: inputDecoration.copyWith(
                    labelText: "起床时间",
                    hintText: "点击选择起床时间",
                    suffixIcon:
                        const Icon(Icons.access_time, color: Colors.blue),
                    suffixText: null,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return TextField(
          controller: valueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: inputDecoration,
          autofocus: autofocus,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  Widget _buildSyncInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          "数据来源: Apple Health",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSyncCard(),
              _buildDataTypeGrid(),
              _buildSyncInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
