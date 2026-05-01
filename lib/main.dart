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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('大兒子投籃位置與角度分析'),
        backgroundColor: Colors.orange[400],
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { shotRecords.clear(); streak=0; }))
        ],
      ),
      body: Column(
        children: [
          // 數據統計區域
          Container(
            padding: const EdgeInsets.all(8),
            child: Card(
              elevation: 2,
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('總投籃', '${shotRecords.length}'),
                    _buildStat('命中', '${shotRecords.where((r)=>r.isMade).length}'),
                    _buildStat('命中率', '${rate.toStringAsFixed(1)}%', isHighlight: rate >= 50),
                    _buildStat('連進', streak.toString(), isHighlight: streak > 0),
                  ],
                ),
              ),
            ),
          ),

          // 控制區域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('目前設定角度: ${currentAngle.toInt()}°', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('進'),
                      selected: nextShotIsMade == true,
                      onSelected: (v) => setState(() => nextShotIsMade = true),
                      selectedColor: Colors.green[200],
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('沒'),
                      selected: nextShotIsMade == false,
                      onSelected: (v) => setState(() => nextShotIsMade = false),
                      selectedColor: Colors.red[200],
                    ),
                  ],
                ),
                Slider(
                  value: currentAngle, min: 0, max: 90, divisions: 90,
                  onChanged: (v) => setState(() => currentAngle = v),
                ),
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

          // 修正後的球場畫布 http://googleusercontent.com/image_content/214


          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: GestureDetector(
                onTapDown: (d) => handleTap(d.localPosition),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isHighlight ? Colors.red : Colors.orange[800])),
      ],
    );
  }
}

class CourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  CourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.grey[400]!..style = PaintingStyle.stroke..strokeWidth = 2;
    
    // 1. 設定籃框位置 (靠近頂部中央)
    final rimCenter = Offset(size.width / 2, size.height * 0.15);
    canvas.drawCircle(rimCenter, 12, linePaint); // 籃框

    // 2. 繪製籃板線
    canvas.drawLine(Offset(size.width / 2 - 25, size.height * 0.12), Offset(size.width / 2 + 25, size.height * 0.12), linePaint);

    // 3. 繪製禁區 (罰球區)
    final keyRect = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.25), width: size.width * 0.3, height: size.height * 0.3);
    canvas.drawRect(keyRect, linePaint);

    // 4. 繪製三分線 (弧線) - 關鍵修正：確保半徑適中
    final threePointRect = Rect.fromCircle(center: rimCenter, radius: size.width * 0.7);
    canvas.drawArc(threePointRect, 0.2, 2.75, false, linePaint);

    // 5. 繪製底線 (封閉球場)
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), linePaint);

    // 繪製投籃點
    for (var r in records) {
      final p = Paint()..color = r.isMade ? Colors.green.withOpacity(0.7) : Colors.red.withOpacity(0.7);
      canvas.drawCircle(r.position, 8, p);
      
      TextPainter(
        text: TextSpan(text: '${r.angle.toInt()}°\n${r.type}', style: const TextStyle(color: Colors.black54, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(r.position.dx - 8, r.position.dy + 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}