import 'package:flutter/material.dart';

void main() => runApp(const BasketballProApp());

class BasketballProApp extends StatelessWidget {
  const BasketballProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      home: const ShotProScreen(),
    );
  }
}

class ShotRecord {
  final Offset position;
  final bool isMade;
  final double angle;
  final String type;
  ShotRecord({required this.position, required this.isMade, required this.angle, required this.type});
}

class ShotProScreen extends StatefulWidget {
  const ShotProScreen({super.key});
  @override
  State<ShotProScreen> createState() => _ShotProScreenState();
}

class _ShotProScreenState extends State<ShotProScreen> {
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 45.0;
  String currentType = '定點';
  int streak = 0;
  int maxStreak = 0;

  void handleTap(Offset pos) {
    setState(() {
      shotRecords.add(ShotRecord(
        position: pos,
        isMade: nextShotIsMade,
        angle: currentAngle,
        type: currentType,
      ));
      if (nextShotIsMade) {
        streak++;
        if (streak > maxStreak) maxStreak = streak;
      } else {
        streak = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double rate = shotRecords.isEmpty ? 0 : (shotRecords.where((r)=>r.isMade).length / shotRecords.length) * 100;

    return Scaffold(
      // 背景設為淡淡的灰色，增加質感
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('大兒子投籃數據分析'),
        backgroundColor: Colors.orange[400],
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { shotRecords.clear(); streak=0; }))
        ],
      ),
      body: Column(
        children: [
          // 數據看板 (優化 1: 遊戲化效果)
          Container(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('命中率', '${rate.toStringAsFixed(1)}%', isHighlight: rate >= 50),
                    _buildStat('連進', streak.toString(), isHighlight: streak > 0),
                    _buildStat('最高連進', maxStreak.toString()),
                  ],
                ),
              ),
            ),
          ),

          // 控制區 (角度滑桿 + 進球開關)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('目前角度: ${currentAngle.toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    Row(
                      children: [
                        _typeButton('定點'), _typeButton('跳投'), _typeButton('運球'),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: currentAngle, min: 0, max: 90, divisions: 90,
                  activeColor: Colors.orange,
                  onChanged: (v) => setState(() => currentAngle = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('紀錄模式：', style: TextStyle(fontSize: 14)),
                    ChoiceChip(
                      label: const Text('進球 ✅'),
                      selected: nextShotIsMade,
                      onSelected: (v) => setState(() => nextShotIsMade = true),
                      selectedColor: Colors.green[100],
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('沒進 ❌'),
                      selected: !nextShotIsMade,
                      onSelected: (v) => setState(() => nextShotIsMade = false),
                      selectedColor: Colors.red[100],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 核心區：放大版專業半圓球場
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: GestureDetector(
                onTapDown: (d) => handleTap(d.localPosition),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('💡 點擊球場位置即可記錄點位', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(String type) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: InkWell(
        onTap: () => setState(() => currentType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: currentType == type ? Colors.orange[100] : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Text(type, style: const TextStyle(fontSize: 10)),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isHighlight ? Colors.red : Colors.orange[800])),
      ],
    );
  }
}

class CourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  CourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 籃框中心點 (置頂中央)
    final rimCenter = Offset(size.width / 2, 60);

    // 1. 畫籃框
    canvas.drawCircle(rimCenter, 15, linePaint);
    
    // 2. 畫籃板
    canvas.drawLine(Offset(size.width / 2 - 35, 40), Offset(size.width / 2 + 35, 40), linePaint);

    // 3. 畫專業比例禁區 (長方形)
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, 130), width: 130, height: 140), linePaint);

    // 4. 畫放大版三分線 (半圓弧)
    // 這裡調大半徑，讓它像 image_66e837 一樣充滿空間
    canvas.drawArc(
      Rect.fromCircle(center: rimCenter, radius: size.width * 0.8),
      0,
      3.14159,
      false,
      linePaint,
    );

    // 5. 繪製投籃點與角度標籤
    for (var r in records) {
      final shotPaint = Paint()
        ..color = r.isMade ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(r.position, 10, shotPaint);

      // 標註角度
      final tp = TextPainter(
        text: TextSpan(
          text: '${r.angle.toInt()}°\n${r.type}',
          style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(r.position.dx - 12, r.position.dy + 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}