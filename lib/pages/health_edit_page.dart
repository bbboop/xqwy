import 'package:flutter/material.dart';
import 'package:healther/services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HealthEditPage extends StatefulWidget {
  const HealthEditPage({Key? key}) : super(key: key);

  @override
  State<HealthEditPage> createState() => _HealthEditPageState();
}

class _HealthEditPageState extends State<HealthEditPage> {
  bool _isLoading = true;
  Map<String, dynamic> _healthData = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  @override
  void dispose() {
    // 清理所有控制器
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService().getHealthDetail();
      if (result['code'] == 200 && result['data'] != null) {
        setState(() {
          _healthData = result['data'];
          // 初始化控制器
          _initControllers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: result['message'] ?? '获取健康数据失败');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: '获取健康数据失败: ${e.toString()}');
    }
  }

  void _initControllers() {
    // 初始化所有字段的控制器
    _controllers['steps'] =
        TextEditingController(text: _healthData['steps']?.toString());
    _controllers['heart_rate'] =
        TextEditingController(text: _healthData['heart_rate']?.toString());
    _controllers['sleep_hours'] =
        TextEditingController(text: _healthData['sleep_hours']?.toString());
    _controllers['weight_kg'] =
        TextEditingController(text: _healthData['weight_kg']?.toString());
    _controllers['blood_glucose_mmol'] = TextEditingController(
        text: _healthData['blood_glucose_mmol']?.toString());
    _controllers['systolic_bp'] =
        TextEditingController(text: _healthData['systolic_bp']?.toString());
    _controllers['diastolic_bp'] =
        TextEditingController(text: _healthData['diastolic_bp']?.toString());
  }

  Future<void> _updateHealthData() async {
    try {
      final result = await ApiService().updateHealthData(
        id: _healthData['id'],
        steps: _controllers['steps']?.text,
        heartRate: _controllers['heart_rate']?.text,
        sleepHours: _controllers['sleep_hours']?.text,
        weightKg: _controllers['weight_kg']?.text,
        bloodGlucoseMmol: _controllers['blood_glucose_mmol']?.text,
        systolicBp: _controllers['systolic_bp']?.text,
        diastolicBp: _controllers['diastolic_bp']?.text,
      );

      if (result['code'] == 200) {
        Fluttertoast.showToast(msg: '更新成功');
        Navigator.pop(context, true); // 返回并刷新
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? '更新失败');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '更新失败: ${e.toString()}');
    }
  }

  Widget _buildTextField({
    required String label,
    required String controllerKey,
    String? unit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _controllers[controllerKey],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: '$label${unit != null ? ' ($unit)' : ''}',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑健康数据'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateHealthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    label: '体重',
                    controllerKey: 'weight_kg',
                    unit: 'kg',
                  ),
                  _buildTextField(
                    label: '心率',
                    controllerKey: 'heart_rate',
                    unit: '次/分',
                  ),
                  _buildTextField(
                    label: '收缩压',
                    controllerKey: 'systolic_bp',
                    unit: 'mmHg',
                  ),
                  _buildTextField(
                    label: '舒张压',
                    controllerKey: 'diastolic_bp',
                    unit: 'mmHg',
                  ),
                  _buildTextField(
                    label: '血糖',
                    controllerKey: 'blood_glucose_mmol',
                    unit: 'mmol/L',
                  ),
                  _buildTextField(
                    label: '睡眠时长',
                    controllerKey: 'sleep_hours',
                    unit: '小时',
                  ),
                  _buildTextField(
                    label: '运动步数',
                    controllerKey: 'steps',
                    unit: '步',
                  ),
                ],
              ),
            ),
    );
  }
}
