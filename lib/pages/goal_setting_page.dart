import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class GoalSettingPage extends StatefulWidget {
  const GoalSettingPage({Key? key}) : super(key: key);

  @override
  State<GoalSettingPage> createState() => _GoalSettingPageState();
}

class _GoalSettingPageState extends State<GoalSettingPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  final TextEditingController _caloriesController = TextEditingController(
    text: '2000',
  );

  // 三餐分配数据
  List<Map<String, dynamic>> _mealControllers = [
    {
      'calories': TextEditingController(text: ''),
    }
  ];

  // 运动项目数据
  List<Map<String, dynamic>> _exerciseControllers = [
    {
      'duration': TextEditingController(text: ''),
    }
  ];

  // 服药计划数据
  List<Map<String, dynamic>> _medicationControllers = [
    {
      'name': TextEditingController(text: ''),
    }
  ];

  // 睡眠目标数据
  List<Map<String, dynamic>> _sleepControllers = [
    {
      'time': TextEditingController(text: ''),
    }
  ];

  final TextEditingController _exerciseTimeController = TextEditingController(
    text: '60',
  );
  final TextEditingController _sleepTimeController = TextEditingController(
    text: '8',
  );

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  Future<void> _fetchGoals() async {
    try {
      final response = await _apiService.getGoals();
      if (response['code'] == 200 && response['data'] != null) {
        final goals = response['data'];
        setState(() {
          // 处理饮食目标
          if (goals['type_1'] != null) {
            _mealControllers = (goals['type_1'] as List).map((item) {
              return {
                'calories': TextEditingController(text: item['content'] ?? ''),
                'id': item['id'],
              };
            }).toList();
          }

          // 处理运动目标
          if (goals['type_2'] != null) {
            _exerciseControllers = (goals['type_2'] as List).map((item) {
              return {
                'duration': TextEditingController(text: item['content'] ?? ''),
                'id': item['id'],
              };
            }).toList();
          }

          // 处理睡眠目标
          if (goals['type_3'] != null) {
            _sleepControllers = (goals['type_3'] as List).map((item) {
              return {
                'time': TextEditingController(text: item['content'] ?? ''),
                'id': item['id'],
              };
            }).toList();
          }

          // 处理药物目标
          if (goals['type_4'] != null) {
            _medicationControllers = (goals['type_4'] as List).map((item) {
              return {
                'name': TextEditingController(text: item['content'] ?? ''),
                'id': item['id'],
              };
            }).toList();
          }

          _isLoading = false;
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

  Future<void> _saveGoals() async {
    try {
      final goals = [
        // 饮食目标
        ..._mealControllers.map((controller) => {
              'type': 1,
              'content': controller['calories']?.text ?? '',
              if (controller['id'] != null) 'id': controller['id'],
            }),
        // 运动目标
        ..._exerciseControllers.map((controller) => {
              'type': 2,
              'content': controller['duration']?.text ?? '',
              if (controller['id'] != null) 'id': controller['id'],
            }),
        // 睡眠目标
        ..._sleepControllers.map((controller) => {
              'type': 3,
              'content': controller['time']?.text ?? '',
              if (controller['id'] != null) 'id': controller['id'],
            }),
        // 药物目标
        ..._medicationControllers.map((controller) => {
              'type': 4,
              'content': controller['name']?.text ?? '',
              if (controller['id'] != null) 'id': controller['id'],
            }),
      ];

      final response = await _apiService.saveGoals(goals);
      if (response['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? '保存失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _saveGoals,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          "保存目标设置",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMealSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "饮食分配",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _mealControllers.add({
                    'calories': TextEditingController(text: ''),
                  });
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._mealControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers['calories'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '饮食内容,如: 早餐 200卡',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      controllers['calories']?.dispose();
                      _mealControllers.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExerciseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "运动项目",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _exerciseControllers.add({
                    'duration': TextEditingController(text: ''),
                  });
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._exerciseControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers['duration'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '运动内容,如: 跑步 30分钟',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      controllers['duration']?.dispose();
                      _exerciseControllers.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSleepSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "睡眠目标",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _sleepControllers.add({
                    'time': TextEditingController(text: ''),
                  });
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._sleepControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers['time'],
                    decoration: InputDecoration(
                      labelText: '睡眠内容,如: 睡眠目标:22:00-07:00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      controllers['time']?.dispose();
                      _sleepControllers.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMedicationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "每日服药计划",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _medicationControllers.add({
                    'name': TextEditingController(text: ''),
                  });
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._medicationControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers['name'],
                    decoration: InputDecoration(
                      labelText: '用药内容,如:早餐前服用维生素',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      controllers['name']?.dispose();
                      _medicationControllers.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '目标设定',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildSection(
                  title: "饮食目标",
                  icon: Icons.restaurant,
                  color: Colors.green,
                  children: [
                    _buildMealSection(),
                  ],
                ),
                _buildSection(
                  title: "运动目标",
                  icon: Icons.fitness_center,
                  color: Colors.orange,
                  children: [
                    _buildExerciseSection(),
                  ],
                ),
                _buildSection(
                  title: "睡眠目标",
                  icon: Icons.nightlight_round,
                  color: Colors.purple,
                  children: [
                    _buildSleepSection(),
                  ],
                ),
                _buildSection(
                  title: "药物目标",
                  icon: Icons.medical_services,
                  color: Colors.blue,
                  children: [
                    _buildMedicationSection(),
                  ],
                ),
                _buildSaveButton(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: SpinKitWave(
                  color: Colors.blue,
                  size: 50.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _exerciseTimeController.dispose();
    _sleepTimeController.dispose();

    // 释放所有动态添加的控制器
    for (var controllers in _mealControllers) {
      controllers['calories']?.dispose();
    }
    for (var controllers in _exerciseControllers) {
      controllers['duration']?.dispose();
    }
    for (var controllers in _sleepControllers) {
      controllers['time']?.dispose();
    }
    for (var controllers in _medicationControllers) {
      controllers['name']?.dispose();
    }

    super.dispose();
  }
}
