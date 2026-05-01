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
  final String type; // 投籃類型
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
  String currentType = '定點'; // 預設投籃類型
  int streak = 0; // 連進紀錄
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('大兒子籃球科學分析'),
        backgroundColor: Colors.orange[400],
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { shotRecords.clear(); streak=0; }))
        ],
      ),
      body: Column(
        children: [
          // 1. 遊戲化數據看板 [優化1]
          Container(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 4,
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('命中率', '${rate.toStringAsFixed(1)}%', isHighlight: rate >= 50),
                        _buildStat('連進', streak.toString(), isHighlight: streak > 0),
                        _buildStat('最高連進', maxStreak.toString()),
                      ],
                    ),
                    if (rate >= 50 && shotRecords.length >= 5) 
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('🔥 進入神射手狀態！', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 2. 角度與模式控制 [優化2]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('角度: ${currentAngle.toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: currentAngle, min: 0, max: 90, divisions: 90,
                        onChanged: (v) => setState(() => currentAngle = v),
                      ),
                    ),
                    Switch(value: nextShotIsMade, activeColor: Colors.green, onChanged: (v) => setState(() => nextShotIsMade = v)),
                    Text(nextShotIsMade ? '進球' : '未進'),
                  ],
                ),
                // 3. 投籃類型標籤 [優化4]
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['定點', '運球', '跳投', '上籃'].map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: currentType == t,
                        onSelected: (s) => setState(() => currentType = t),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 4. 放大版球場 [優化：場地變大]
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[200]!, width: 2),
              ),
              child: GestureDetector(
                onTapDown: (d) => handleTap(d.localPosition),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text('點擊球場紀錄位置', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isHighlight ? Colors.red : Colors.orange[800])),
      ],
    );
  }
}

class CourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  CourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.orange[200]!..style = PaintingStyle.stroke..strokeWidth = 3;
    final center = Offset(size.width / 2, 60);

    // 繪製加大版球場線條
    canvas.drawCircle(center, 15, linePaint); // 籃框
    canvas.drawRect(Rect.fromCenter(center: Offset(size.width / 2, 100), width: 120, height: 140), linePaint); // 禁區
    canvas.drawArc(Rect.fromCircle(center: center, radius: size.width * 0.8), 0, 3.14, false, linePaint); // 三分線

    for (var r in records) {
      final p = Paint()..color = r.isMade ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8);
      canvas.drawCircle(r.position, 10, p);
      
      // 顯示角度與類型
      TextPainter(
        text: TextSpan(text: '${r.angle.toInt()}°\n${r.type}', style: const TextStyle(color: Colors.black87, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(r.position.dx - 10, r.position.dy + 12));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}