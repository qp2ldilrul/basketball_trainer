import 'package:flutter/material.dart';

void main() {
  runApp(const BasketballProApp());
}

class BasketballProApp extends StatelessWidget {
  const BasketballProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '投籃數據分析系統',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const ShotProScreen(),
    );
  }
}

class ShotRecord {
  final Offset position;
  final bool isMade;
  final double angle;
  final String type;

  ShotRecord({
    required this.position,
    required this.isMade,
    required this.angle,
    required this.type,
  });
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

  void handleTap(Offset localPosition) {
    setState(() {
      shotRecords.add(ShotRecord(
        position: localPosition,
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

  void resetData() {
    setState(() {
      shotRecords.clear();
      streak = 0;
      maxStreak = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    int total = shotRecords.length;
    int made = shotRecords.where((r) => r.isMade).length;
    double rate = total == 0 ? 0 : (made / total) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('投籃數據分析系統', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: resetData),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: Colors.orange[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('總次數', total.toString(), Colors.white),
                _buildStat('命中', made.toString(), Colors.greenAccent),
                _buildStat('命中率', '${rate.toStringAsFixed(1)}%', Colors.yellowAccent),
                _buildStat('當前連進', streak.toString(), Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('目前角度: ${currentAngle.toInt()}°', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        _statusBtn(true, '進球'),
                        const SizedBox(width: 8),
                        _statusBtn(false, '沒進'),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: currentAngle,
                  min: 0, max: 90, divisions: 90,
                  activeColor: Colors.orange,
                  onChanged: (v) => setState(() => currentAngle = v),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['定點', '跳投', '運球', '上籃', '勾射'].map((t) => Padding(
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
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.orange[100]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: GestureDetector(
                  onTapDown: (d) => handleTap(d.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: ScaledCourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String l, String v, Color c) => Column(children: [Text(l, style: const TextStyle(color: Colors.white70)), Text(v, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold))]);

  Widget _statusBtn(bool m, String l) {
    bool s = nextShotIsMade == m;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: s ? (m ? Colors.green : Colors.red) : Colors.grey[200], borderRadius: BorderRadius.circular(15)),
        child: Text(l, style: TextStyle(color: s ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ScaledCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  ScaledCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey[300]!..style = PaintingStyle.stroke..strokeWidth = 2.5;
    double cx = size.width / 2;
    double top = 30.0;

    // 1. 底線
    canvas.drawLine(Offset(0, top), Offset(size.width, top), paint);

    // 2. 禁區 (中間區域縮小)
    // 寬度從 width * 0.45 縮小為 width * 0.35
    double kw = size.width * 0.35;
    // 高度也適度縮減
    double kh = size.height * 0.35;
    canvas.drawRect(Rect.fromLTWH(cx - kw / 2, top, kw, kh), paint);

    // 3. 罰球弧
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, top + kh), width: kw, height: kw), 0, 3.14159, false, paint);

    // 4. 籃框系統
    canvas.drawCircle(Offset(cx, top + 20), 18, paint);
    canvas.drawLine(Offset(cx - 30, top + 5), Offset(cx + 30, top + 5), paint);

    // 5. 三分線 (調整半徑確保能顯示完整)
    // 半徑設為畫布寬度的 40%
    double threeRadius = size.width * 0.4;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, top + 20), radius: threeRadius),
      0.1, 2.94, false, paint
    );
    // 三分線底角直線
    canvas.drawLine(Offset(cx - threeRadius, top), Offset(cx - threeRadius, top + 20), paint);
    canvas.drawLine(Offset(cx + threeRadius, top), Offset(cx + threeRadius, top + 20), paint);

    // 6. 點位標註
    for (var r in records) {
      final p = Paint()..color = r.isMade ? Colors.green : Colors.red..style = PaintingStyle.fill;
      canvas.drawCircle(r.position, 10, p);
      canvas.drawCircle(r.position, 10, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

      TextPainter(
        text: TextSpan(
          text: '${r.angle.toInt()}° ${r.type}',
          style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(r.position.dx - 10, r.position.dy + 12));
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}