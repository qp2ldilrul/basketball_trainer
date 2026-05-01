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
  // 核心數據
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 45.0;
  String currentType = '定點';
  int streak = 0;

  // 1. 處理點擊紀錄
  void handleTap(Offset localPosition) {
    setState(() {
      shotRecords.add(ShotRecord(
        position: localPosition,
        isMade: nextShotIsMade,
        angle: currentAngle,
        type: currentType,
      ));
      _recalculateStreak();
    });
  }

  // 2. 復原功能 (Undo)
  void undoLastAction() {
    if (shotRecords.isNotEmpty) {
      setState(() {
        shotRecords.removeLast();
        _recalculateStreak();
      });
    }
  }

  // 3. 重新計算連進次數 (Streak)
  void _recalculateStreak() {
    int currentStreak = 0;
    for (var i = shotRecords.length - 1; i >= 0; i--) {
      if (shotRecords[i].isMade) {
        currentStreak++;
      } else {
        break;
      }
    }
    streak = currentStreak;
  }

  // 4. 重置功能
  void resetData() {
    setState(() {
      shotRecords.clear();
      streak = 0;
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
        title: const Text('投籃數據分析系統', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.undo_rounded),
          onPressed: shotRecords.isEmpty ? null : undoLastAction,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: resetData),
        ],
      ),
      body: Column(
        children: [
          // 數據看板
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.orange[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('次數', total.toString(), Colors.white),
                _buildStat('命中', made.toString(), Colors.greenAccent),
                _buildStat('命中率', '${rate.toStringAsFixed(1)}%', Colors.yellowAccent),
                _buildStat('連進', streak.toString(), Colors.white),
              ],
            ),
          ),
          // 控制區
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${currentAngle.toInt()}°', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        _toggleBtn(true, '進球'),
                        const SizedBox(width: 5),
                        _toggleBtn(false, '沒進'),
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
                      padding: const EdgeInsets.only(right: 5),
                      child: ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: currentType == t,
                        onSelected: (s) => setState(() => currentType = t),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          // 球場區
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange[50]!, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: GestureDetector(
                  onTapDown: (d) => handleTap(d.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: FinalCourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String l, String v, Color c) => Column(children: [
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    Text(v, style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.bold))
  ]);

  Widget _toggleBtn(bool m, String l) {
    bool s = nextShotIsMade == m;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: s ? (m ? Colors.green : Colors.red) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(l, style: TextStyle(color: s ? Colors.white : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class FinalCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  FinalCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey[200]!..style = PaintingStyle.stroke..strokeWidth = 2.0;
    double cx = size.width / 2;
    double top = 20.0;

    // 1. 底線
    canvas.drawLine(Offset(0, top), Offset(size.width, top), paint);

    // 2. 禁區 (針對 iPad 分割畫面優化：寬度 30%)
    double kw = size.width * 0.3;
    double kh = size.height * 0.3;
    canvas.drawRect(Rect.fromLTWH(cx - kw / 2, top, kw, kh), paint);

    // 3. 罰球弧
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, top + kh), width: kw, height: kw), 0, 3.14, false, paint);

    // 4. 籃框
    canvas.drawCircle(Offset(cx, top + 15), 12, paint);
    canvas.drawLine(Offset(cx - 20, top + 5), Offset(cx + 20, top + 5), paint);

    // 5. 三分線 (縮小半徑以適應窄長螢幕)
    double threeRadius = size.width * 0.38;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, top + 15), radius: threeRadius),
      0, 3.14, false, paint
    );
    canvas.drawLine(Offset(cx - threeRadius, top), Offset(cx - threeRadius, top + 15), paint);
    canvas.drawLine(Offset(cx + threeRadius, top), Offset(cx + threeRadius, top + 15), paint);

    // 6. 點位
    for (var r in records) {
      final p = Paint()..color = r.isMade ? Colors.green : Colors.red..style = PaintingStyle.fill;
      canvas.drawCircle(r.position, 8, p);
      canvas.drawCircle(r.position, 8, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}