import 'package:flutter/material.dart';

class BodyModel extends StatelessWidget {
  final Function(String) onPartTap;
  final bool isMale;
  final Map<String, bool> selectedTypes;

  const BodyModel({
    Key? key,
    required this.onPartTap,
    required this.isMale,
    required this.selectedTypes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 350,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 基础人体图片
          Image.asset(
            isMale ? 'assets/images/man.png' : 'assets/images/women.png',
            height: 350,
            fit: BoxFit.contain,
          ),
          // 可点击区域
          ..._buildTapAreas(),
        ],
      ),
    );
  }

  List<Widget> _buildTapAreas() {
    return [
      // 头部 - 睡眠
      if (selectedTypes['sleep'] ?? true)
        Positioned(
          top: 10,
          left: 100,
          child: _buildTapArea(
            width: 45,
            height: 45,
            onTap: () => onPartTap('head'),
            tooltip: '睡眠',
            color: Colors.orange,
            icon: Icons.nightlight_round,
          ),
        ),
      // 心脏位置 - 心率
      if (selectedTypes['heart'] ?? true)
        Positioned(
          top: 120,
          right: 120,
          child: _buildTapArea(
            width: 40,
            height: 40,
            onTap: () => onPartTap('heart'),
            tooltip: '心率',
            color: Colors.red,
            icon: Icons.favorite,
          ),
        ),
      // 手臂位置 - 血压
      if (selectedTypes['blood_pressure'] ?? true)
        Positioned(
          top: 130,
          left: 80,
          child: _buildTapArea(
            width: 40,
            height: 40,
            onTap: () => onPartTap('arm'),
            tooltip: '血压',
            color: Colors.blue,
            icon: Icons.water_drop,
          ),
        ),
      // 腹部位置 - 血糖
      if (selectedTypes['blood_sugar'] ?? true)
        Positioned(
          top: 140,
          right: 40,
          child: _buildTapArea(
            width: 40,
            height: 40,
            onTap: () => onPartTap('abdomen'),
            tooltip: '血糖',
            color: Colors.purple,
            icon: Icons.bloodtype,
          ),
        ),
      // 腿部位置 - 运动
      if (selectedTypes['exercise'] ?? true)
        Positioned(
          bottom: 20,
          right: 140,
          child: _buildTapArea(
            width: 40,
            height: 40,
            onTap: () => onPartTap('legs'),
            tooltip: '运动',
            color: Colors.green,
            icon: Icons.directions_run,
          ),
        ),
      // 整体位置 - 体重
      if (selectedTypes['weight'] ?? true)
        Positioned(
          top: 180,
          right: 150,
          child: _buildTapArea(
            width: 40,
            height: 40,
            onTap: () => onPartTap('weight'),
            tooltip: '体重',
            color: Colors.blue,
            icon: Icons.monitor_weight,
          ),
        ),
    ];
  }

  Widget _buildTapArea({
    required double width,
    required double height,
    required VoidCallback onTap,
    required String tooltip,
    required Color color,
    required IconData icon,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(width / 2),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: width * 0.5),
          ),
        ),
      ),
    );
  }
}
