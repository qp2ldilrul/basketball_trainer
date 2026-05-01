import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const BasketballTrainerApp());
}

class BasketballTrainerApp extends StatelessWidget {
  const BasketballTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '大兒子投籃記錄',
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      home: const ShotTrackerPage(),
    );
  }
}

class ShotTrackerPage extends StatefulWidget {
  const ShotTrackerPage({super.key});

  @override
  State<ShotTrackerPage> createState() => _ShotTrackerPageState();
}

class _ShotTrackerPageState extends State<ShotTrackerPage> {
  List<ShotData> shots = [];

  void _addShot(Offset position, bool isMade) {
    setState(() {
      shots.add(ShotData(position: position, isMade: isMade));
    });
  }

  @override
  Widget build(BuildContext context) {
    int madeShots = shots.where((s) => s.isMade).length;
    double accuracy = shots.isEmpty ? 0 : (madeShots / shots.length) * 100;

    return Scaffold(
      // 背景設為透明感，方便妳疊加在相機畫面上
      backgroundColor: Colors.white.withOpacity(0.9),
      appBar: AppBar(
        title: const Text('大兒子投籃分析'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => shots.clear()),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 球場參考線 (半透明)
          Positioned.fill(
            child: CustomPaint(painter: CourtPainter()),
          ),

          // 2. 點擊偵測與點位顯示
          Positioned.fill(
            child: GestureDetector(
              onTapUp: (details) => _showShotDialog(details.localPosition),
              child: Stack(
                children: [
                  ...shots.map((shot) => Positioned(
                        left: shot.position.dx - 15,
                        top: shot.position.dy - 15,
                        child: Icon(
                          shot.isMade ? Icons.check_circle : Icons.cancel,
                          color: shot.isMade ? Colors.green : Colors.red,
                          size: 30,
                        ),
                      )),
                ],
              ),
            ),
          ),

          // 3. 上方即時看板
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat("總投籃", "${shots.length}"),
                  _buildStat("命中", "$madeShots"),
                  _buildStat("命中率", "${accuracy.toStringAsFixed(1)}%"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShotDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('記錄結果'),
        actions: [
          TextButton(
            onPressed: () { _addShot(position, false); Navigator.pop(context); },
            child: const Text('沒進', style: TextStyle(color: Colors.red, fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () { _addShot(position, true); Navigator.pop(context); },
            child: const Text('進球', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
      ],
    );
  }
}

class ShotData {
  final Offset position;
  final bool isMade;
  ShotData({required this.position, required this.isMade});
}

class CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 畫籃框位置
    canvas.drawCircle(Offset(size.width * 0.5, 60), 12, paint..color = Colors.red.withOpacity(0.3));
    // 畫三分線
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.5, 60), radius: size.width * 0.45),
      0, pi, false, paint..color = Colors.grey.withOpacity(0.3)
    );
    // 畫禁區
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, 20, size.width * 0.4, 180), paint);
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}