import 'package:flutter/material.dart';

void main() {
  runApp(const BasketballTrainerApp());
}

class BasketballTrainerApp extends StatelessWidget {
  const BasketballTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const ShotMapScreen(),
    );
  }
}

// 增加 angle 欄位紀錄角度
class ShotRecord {
  final Offset position;
  final bool isMade;
  final double angle; 
  ShotRecord({required this.position, required this.isMade, required this.angle});
}

class ShotMapScreen extends StatefulWidget {
  const ShotMapScreen({super.key});

  @override
  State<ShotMapScreen> createState() => _ShotMapScreenState();
}

class _ShotMapScreenState extends State<ShotMapScreen> {
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 45.0; // 預設投籃角度為 45 度

  int get totalShots => shotRecords.length;
  int get madeShots => shotRecords.where((r) => r.isMade).length;
  double get madeRate => totalShots > 0 ? (madeShots / totalShots) * 100 : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('大兒子投籃位置與角度分析'),
        backgroundColor: Colors.orange[400],
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => setState(() => shotRecords.clear())),
        ],
      ),
      body: Column(
        children: [
          // 數據看板
          Container(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('總投籃', totalShots.toString()),
                    _buildStat('命中', madeShots.toString()),
                    _buildStat('命中率', '${madeRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
          ),
          
          // 角度滑桿區域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('目前設定角度: ${currentAngle.toInt()}°', 
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('進球'),
                          selected: nextShotIsMade,
                          onSelected: (val) => setState(() => nextShotIsMade = true),
                          selectedColor: Colors.green[200],
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('沒進'),
                          selected: !nextShotIsMade,
                          onSelected: (val) => setState(() => nextShotIsMade = false),
                          selectedColor: Colors.red[200],
                        ),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: currentAngle,
                  min: 0,
                  max: 90,
                  divisions: 90,
                  label: '${currentAngle.toInt()}°',
                  onChanged: (double value) {
                    setState(() {
                      currentAngle = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // 繪製半圓球場
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: GestureDetector(
                onTapDown: (details) {
                  setState(() {
                    shotRecords.add(ShotRecord(
                      position: details.localPosition, 
                      isMade: nextShotIsMade,
                      angle: currentAngle,
                    ));
                  });
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: CustomPaint(
                    painter: CourtPainter(shotRecords: shotRecords),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('提示：先調整上方角度，再點擊球場位置記錄', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
      ],
    );
  }
}

class CourtPainter extends CustomPainter {
  final List<ShotRecord> shotRecords;
  CourtPainter({required this.shotRecords});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 畫籃框
    canvas.drawCircle(Offset(size.width / 2, 50), 12, paint);
    // 畫三分線
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, 50), radius: size.width * 0.7),
      0,
      3.14,
      false,
      paint,
    );
    // 畫禁區
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width/2, 100), width: 100, height: 100), paint);

    // 繪製投籃點（包含角度資訊）
    for (var record in shotRecords) {
      final shotPaint = Paint()
        ..color = record.isMade ? Colors.green.withOpacity(0.7) : Colors.red.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(record.position, 8, shotPaint);
      
      // 在點點下方顯示角度小文字
      TextPainter(
        text: TextSpan(
          text: '${record.angle.toInt()}°',
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(record.position.dx - 10, record.position.dy + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}