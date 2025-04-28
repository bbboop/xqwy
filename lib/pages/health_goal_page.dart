import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'goal_setting_page.dart';
import '../services/api_service.dart';
import 'food_recognition_page.dart';
import '../services/health_service.dart';

class HealthGoalPage extends StatefulWidget {
  const HealthGoalPage({Key? key}) : super(key: key);

  @override
  State<HealthGoalPage> createState() => _HealthGoalPageState();
}

class _HealthGoalPageState extends State<HealthGoalPage> {
  final logger = Logger();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // 健康详情数据
  double _caloriesBurnedToday = 0;
  double _exerciseMinutes = 0;
  double _sleepHours = 0;

  // 目标值
  double _targetCalories = 0;
  double _targetExercise = 0;
  double _targetSleep = 0;

  // 存储每个目标的任务列表
  final Map<String, List<GoalTask>> _goalTasks = {
    "饮食目标": [],
    "运动目标": [],
    "睡眠目标": [],
    "药物目标": [],
  };

  // 解析目标中的数值
  double _parseNumericValue(String text, String unit) {
    final RegExp regex = RegExp(r'(\d+(?:\.\d+)?)\s*' + unit);
    final match = regex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }

  // 计算目标总值
  void _calculateTargets() {
    _targetCalories = 0;
    _targetExercise = 0;
    _targetSleep = 0;

    for (var task in _goalTasks['饮食目标'] ?? []) {
      _targetCalories += _parseNumericValue(task.title, '卡');
    }

    for (var task in _goalTasks['运动目标'] ?? []) {
      _targetExercise += _parseNumericValue(task.title, '千卡');
    }

    for (var task in _goalTasks['睡眠目标'] ?? []) {
      _targetSleep += _parseNumericValue(task.title, '小时');
    }
  }

  // 获取状态提示
  Widget _buildStatusMessage(String type) {
    String message = '';
    Color color = Colors.black;
    double progress = 0.0;
    String progressText = '';

    switch (type) {
      case '饮食目标':
        if (_targetCalories > 0) {
          progress = _caloriesBurnedToday / _targetCalories;
          progressText = '$_caloriesBurnedToday/$_targetCalories';
          if (_caloriesBurnedToday > _targetCalories) {
            message = '今日卡路里摄入已超标，请注意控制饮食';
            color = Colors.red;
          } else {
            message = '今日卡路里摄入正常，请继续保持';
            color = Colors.green;
          }
        }
        break;
      case '运动目标':
        if (_targetExercise > 0) {
          progress = _exerciseMinutes / _targetExercise;
          progressText = '$_exerciseMinutes/$_targetExercise';
          if (_exerciseMinutes >= _targetExercise) {
            message = '今日运动量已达标，请继续保持';
            color = Colors.green;
          } else {
            message = '今日运动量未达标，请继续加油';
            color = Colors.orange;
          }
        }
        break;
      case '睡眠目标':
        if (_targetSleep > 0) {
          progress = _sleepHours / _targetSleep;
          progressText = '$_sleepHours/$_targetSleep';
          if (_sleepHours >= _targetSleep) {
            message = '昨日睡眠时间已达标，请继续保持';
            color = Colors.green;
          } else {
            message = '昨日睡眠时间未达标，请继续加油';
            color = Colors.orange;
          }
        }
        break;
    }

    if (message.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_targetCalories > 0 || _targetExercise > 0 || _targetSleep > 0) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: .1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progressText,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: .3)),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchGoals();
    _fetchCaloriesBurned();
    _fetchHealthMetrics();
  }

  // 获取卡路里消耗
  Future<void> _fetchCaloriesBurned() async {
    try {
      final response = await _apiService.getHealthDetail();

      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            _caloriesBurnedToday =
                convertStringToDouble(data['calories_burned_today'] ?? 0);
          });
        }
      }
    } catch (e, stackTrace) {
      logger.e('获取卡路里数据失败', error: e, stackTrace: stackTrace);
    }
  }

  // 获取运动和睡眠数据
  Future<void> _fetchHealthMetrics() async {
    try {
      final HealthService healthService = HealthService();
      bool hasPermission = await healthService.requestHealthPermission();

      if (!hasPermission) {
        return;
      }

      final healthData = await healthService.fetchHealthData();

      final processedData = await healthService.processHealthData(healthData);

      try {
        // 处理运动数据
        final dynamic rawExerciseValue = processedData['active_energy_today'];
        double exerciseValue;
        if (rawExerciseValue is num) {
          exerciseValue = rawExerciseValue.toDouble();
        } else if (rawExerciseValue is String) {
          exerciseValue = double.tryParse(rawExerciseValue) ?? 0.0;
        } else {
          exerciseValue = 0.0;
        }

        // 处理睡眠数据
        final dynamic rawSleepValue =
            processedData['average_sleep_hours_today'];
        double sleepValue;
        if (rawSleepValue is num) {
          sleepValue = rawSleepValue.toDouble();
        } else if (rawSleepValue is String) {
          sleepValue = double.tryParse(rawSleepValue) ?? 0.0;
        } else {
          sleepValue = 0.0;
        }

        if (!mounted) return;

        setState(() {
          _exerciseMinutes = exerciseValue;
          _sleepHours = sleepValue;
        });
      } catch (parseError) {
        rethrow;
      }
    } catch (e, stackTrace) {
      logger.e('获取健康指标失败', error: e, stackTrace: stackTrace);
    }
  }

  double convertStringToDouble(String str) {
    // 清理字符串：去除空格，替换逗号为点
    String cleanedStr = str.trim().replaceAll(',', '.');

    double? number = double.tryParse(cleanedStr);

    if (number != null) {
      return number;
    } else {
      return 0;
    }
  }

  Future<void> _fetchGoals() async {
    try {
      final response = await _apiService.getTodayGoals();
      if (response['code'] == 200 && response['data'] != null) {
        final goals = response['data'];
        setState(() {
          // 处理饮食目标
          if (goals['type_1'] != null) {
            _goalTasks['饮食目标'] = (goals['type_1'] as List).map((item) {
              return GoalTask(
                title: item['content'] ?? '',
                isCompleted: item['is_completed'] ?? 1,
                id: item['id'],
              );
            }).toList();
          }

          // 处理运动目标
          if (goals['type_2'] != null) {
            _goalTasks['运动目标'] = (goals['type_2'] as List).map((item) {
              return GoalTask(
                title: item['content'] ?? '',
                isCompleted: item['is_completed'] ?? 1,
                id: item['id'],
              );
            }).toList();
          }

          // 处理睡眠时间
          if (goals['type_3'] != null) {
            _goalTasks['睡眠目标'] = (goals['type_3'] as List).map((item) {
              return GoalTask(
                title: item['content'] ?? '',
                isCompleted: item['is_completed'] ?? 1,
                id: item['id'],
              );
            }).toList();
          }

          // 处理药物目标
          if (goals['type_4'] != null) {
            _goalTasks['药物目标'] = (goals['type_4'] as List).map((item) {
              return GoalTask(
                title: item['content'] ?? '',
                isCompleted: item['is_completed'] ?? 1,
                id: item['id'],
              );
            }).toList();
          }

          _isLoading = false;
          _calculateTargets(); // 计算目标值
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('获取目标设置失败')),
      //   );
      // }
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                      "健康目标",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "追踪你的健康进度",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalSettingPage(),
                    ),
                  );
                  // 如果保存成功，刷新数据
                  if (result == true) {
                    _fetchGoals();
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: .1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<GoalTask> tasks,
  }) {
    String rightText = '';
    Widget? rightButton;

    // 根据不同类型显示不同的数据
    switch (title) {
      case "饮食目标":
        rightText = "${_caloriesBurnedToday.toStringAsFixed(1)}千卡";
        rightButton = IconButton(
          icon: const Icon(Icons.camera_alt, color: Colors.blue),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FoodRecognitionPage()),
            );
            // 页面返回后重新获取卡路里数据
            _fetchCaloriesBurned();
          },
        );
        break;
      case "运动目标":
        rightText = "${_exerciseMinutes.toStringAsFixed(1)}千卡";
        break;
      case "睡眠目标":
        rightText = "${_sleepHours.toStringAsFixed(1)}小时";
        break;
      default:
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              if (rightText.isNotEmpty)
                Text(
                  rightText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              if (rightButton != null) rightButton,
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[900],
                ),
              ),
            );
          }),
          _buildStatusMessage(title),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildGoalItem(
                      title: "饮食目标",
                      subtitle: "每日饮食计划",
                      icon: Icons.restaurant,
                      color: Colors.green,
                      tasks: _goalTasks["饮食目标"]!,
                    ),
                    _buildGoalItem(
                      title: "运动目标",
                      subtitle: "每日运动计划",
                      icon: Icons.fitness_center,
                      color: Colors.orange,
                      tasks: _goalTasks["运动目标"]!,
                    ),
                    _buildGoalItem(
                      title: "睡眠目标",
                      subtitle: "每日作息计划",
                      icon: Icons.nightlight_round,
                      color: Colors.purple,
                      tasks: _goalTasks["睡眠目标"]!,
                    ),
                    _buildGoalItem(
                      title: "药物目标",
                      subtitle: "每日服药计划",
                      icon: Icons.medical_services,
                      color: Colors.blue,
                      tasks: _goalTasks["药物目标"]!,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

class GoalTask {
  final String title;
  int isCompleted; // 1: 未完成, 2: 已完成
  final int? id;

  GoalTask({required this.title, required this.isCompleted, this.id});
}
