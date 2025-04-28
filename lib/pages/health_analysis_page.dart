import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HealthAnalysisPage extends StatefulWidget {
  const HealthAnalysisPage({Key? key}) : super(key: key);

  @override
  State<HealthAnalysisPage> createState() => _HealthAnalysisPageState();
}

class _HealthAnalysisPageState extends State<HealthAnalysisPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;
  bool _isGeneratingGoals = false;

  @override
  void initState() {
    super.initState();
    _fetchAnalysisData(0);
  }

  Future<void> _fetchAnalysisData([int isManual = 0]) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.getAIAnalysis(isManual);
      if (response['code'] == 200) {
        setState(() {
          _analysisData = response['data'];
          _isLoading = false;
        });
      } else if (response['code'] == 501) {
        setState(() {
          _analysisData = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: response['message'],
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 处理错误
    }
  }

  Widget _buildAIAssistantCard() {
    if (_isLoading) {
      return const Center(
        child: SpinKitFadingCircle(
          color: Color(0xFF9C27B0),
          size: 50.0,
        ),
      );
    }

    final healthScore = _analysisData?['health_score'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'AI健康助手',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _fetchAnalysisData(1),
                  tooltip: '重新生成',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '您的整体健康状况${healthScore >= 80 ? '良好' : '需要改善'}。',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '健康评分',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '$healthScore/100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: healthScore / 100,
                backgroundColor: Colors.white.withValues(alpha: .2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '更新于: ${DateTime.now().toString().split(' ')[0]}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(
    String title,
    String description,
    Color color,
    IconData icon,
    String status,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0.15,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[900]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    final healthAnalysis = _analysisData?['health_analysis'] ?? {};

    return Card(
      color: Colors.white,
      elevation: 0.15,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  '健康趋势分析',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTrendItem(
              icon: Icons.restaurant,
              color: Colors.orange,
              title: '饮食分析',
              description: healthAnalysis['diet'] ?? '暂无饮食分析数据',
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              icon: Icons.directions_run,
              color: Colors.blue,
              title: '运动分析',
              description: healthAnalysis['sport'] ?? '暂无运动分析数据',
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              icon: Icons.nightlight_round,
              color: Colors.purple,
              title: '睡眠分析',
              description: healthAnalysis['sleep'] ?? '暂无睡眠分析数据',
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              icon: Icons.medication,
              color: Colors.red,
              title: '用药分析',
              description: healthAnalysis['medicine'] ?? '暂无用药分析数据',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSuggestions() {
    final healthSuggestions = _analysisData?['health_suggestion'] ?? {};

    return Card(
      color: Colors.white,
      elevation: 0.15,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  '个性化健康建议',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTrendItem(
              icon: Icons.restaurant,
              color: Colors.orange,
              title: '饮食建议',
              description: healthSuggestions['diet'] ?? '暂无饮食建议',
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              icon: Icons.directions_run,
              color: Colors.blue,
              title: '运动建议',
              description: healthSuggestions['sport'] ?? '暂无运动建议',
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              icon: Icons.nightlight_round,
              color: Colors.purple,
              title: '睡眠建议',
              description: healthSuggestions['sleep'] ?? '暂无睡眠建议',
            ),
            const SizedBox(height: 12),
            _buildTrendItem(
              icon: Icons.medication,
              color: Colors.red,
              title: '用药建议',
              description: healthSuggestions['medicine'] ?? '暂无用药建议',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[900]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateGoalsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isGeneratingGoals ? null : _generateWeeklyGoals,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: const Color(0xFF9C27B0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isGeneratingGoals
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: SpinKitFadingCircle(
                    color: Colors.white,
                    size: 20.0,
                  ),
                )
              : const Text(
                  '生成健康目标',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _generateWeeklyGoals() async {
    // 显示确认对话框
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认生成'),
          content: const Text('生成后将覆盖当前目标，是否继续？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('确认'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isGeneratingGoals = true;
    });

    try {
      final response = await _apiService.autoGenerateWeeklyGoals();
      if (response['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('健康目标已成功生成'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? '生成健康目标失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('生成健康目标时发生错误'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingGoals = false;
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 80,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '基础数据过少',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '更新苹果健康数据\n或前往个人中心补充数据',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _fetchAnalysisData(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              '刷新数据',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: SpinKitWave(
            color: Color(0xFF9C27B0),
            size: 50.0,
          ),
        ),
      );
    }

    if (_analysisData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('AI健康分析'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
        ),
        body: _buildEmptyState(),
      );
    }

    final extraAnalysis = _analysisData?['extra_analysis'] ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI健康分析'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIAssistantCard(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                '健康指标分析',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _buildHealthIndicator(
              '体重管理',
              extraAnalysis['weight_management']?['analysis'] ?? '暂无数据',
              Colors.green,
              Icons.monitor_weight,
              extraAnalysis['weight_management']?['rating'] ?? '未知',
            ),
            _buildHealthIndicator(
              '心血管健康',
              extraAnalysis['cardiovascular_management']?['analysis'] ?? '暂无数据',
              Colors.blue,
              Icons.favorite,
              extraAnalysis['cardiovascular_management']?['rating'] ?? '未知',
            ),
            _buildHealthIndicator(
              '睡眠质量',
              extraAnalysis['sleep_quality']?['analysis'] ?? '暂无数据',
              Colors.amber,
              Icons.nightlight_round,
              extraAnalysis['sleep_quality']?['rating'] ?? '未知',
            ),
            _buildHealthIndicator(
              '运动活跃度',
              extraAnalysis['sports_activity']?['analysis'] ?? '暂无数据',
              Colors.purple,
              Icons.directions_run,
              extraAnalysis['sports_activity']?['rating'] ?? '未知',
            ),
            _buildTrendAnalysis(),
            _buildHealthSuggestions(),
            const SizedBox(height: 20),
            _buildGenerateGoalsButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
