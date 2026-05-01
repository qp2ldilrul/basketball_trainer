import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:math' as math;
import 'package:intl/intl.dart';

void main() {
  runApp(const BasketballProApp());
}

class BasketballProApp extends StatelessWidget {
  const BasketballProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '科技投籃數據分析',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
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
  final Color color;

  ShotRecord({
    required this.position,
    required this.isMade,
    required this.angle,
    required this.type,
    required this.color,
  });
}

class ShotProScreen extends StatefulWidget {
  const ShotProScreen({super.key});

  @override
  State<ShotProScreen> createState() => _ShotProScreenState();
}

class _ShotProScreenState extends State<ShotProScreen> {
  // 狀態變數
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 0.0;
  String currentType = '定點';
  int streak = 0;

  // 獨立罰球計數
  int ftTotal = 0;
  int ftMade = 0;

  final Map<String, Color> typeColors = {
    '定點': Colors.cyanAccent,
    '跳投': Colors.purpleAccent,
    '運球': Colors.amberAccent,
    '上籃': Colors.greenAccent,
    '勾射': Colors.orangeAccent,
  };

  void handleCourtTap(Offset localPosition, Size boxSize) {
    HapticFeedback.selectionClick();
    double basketX = boxSize.width * 0.08;
    double basketY = boxSize.height * 0.5;
    double dx = localPosition.dx - basketX;
    double dy = localPosition.dy - basketY;
    double degrees = math.atan2(dy, dx) * 180 / math.pi;

    setState(() {
      currentAngle = degrees.abs();
      shotRecords.add(ShotRecord(
        position: localPosition,
        isMade: nextShotIsMade,
        angle: currentAngle,
        type: currentType,
        color: typeColors[currentType]!,
      ));
      _calculateStreak();
    });
  }

  void _calculateStreak() {
    int s = 0;
    for (int i = shotRecords.length - 1; i >= 0; i--) {
      if (shotRecords[i].isMade) s++; else break;
    }
    streak = s;
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy / MM / dd').format(DateTime.now());
    int total = shotRecords.length;
    int made = shotRecords.where((r) => r.isMade).length;
    double acc = total == 0 ? 0 : (made / total) * 100;
    double ftAcc = ftTotal == 0 ? 0 : (ftMade / ftTotal) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text('PRO COURT ANALYTICS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(today, style: const TextStyle(fontSize: 12, color: Colors.orangeAccent)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.undo), 
          onPressed: () => setState(() {
            if(shotRecords.isNotEmpty) shotRecords.removeLast();
            _calculateStreak();
          })
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent), 
            onPressed: () => setState(() {
              shotRecords.clear();
              streak = 0;
              ftTotal = 0;
              ftMade = 0;
            })
          ),
        ],
      ),
      body: Column(
        children: [
          // 頂部完整數據列
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF252525),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('SHOTS', total.toString(), Colors.white),
                _buildStatItem('MADE', made.toString(), Colors.orangeAccent),
                _buildStatItem('ACC%', '${acc.toStringAsFixed(1)}%', Colors.cyanAccent),
                _buildStatItem('STREAK', streak.toString(), Colors.yellowAccent),
              ],
            ),
          ),
          
          // 獨立罰球區塊
          Container(
            margin: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Text('罰球數據：', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                Expanded(child: Text('投 $ftTotal / 中 $ftMade (${ftAcc.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 14))),
                _ftActionBtn(Icons.add, Colors.grey, () => setState(() => ftTotal++)),
                const SizedBox(width: 10),
                _ftActionBtn(Icons.sports_basketball, Colors.orangeAccent, () => setState(() { ftTotal++; ftMade++; })),
                const SizedBox(width: 10),
                _ftActionBtn(Icons.remove, Colors.redAccent.withOpacity(0.5), () => setState(() { if(ftTotal > 0) ftTotal--; if(ftMade > ftTotal) ftMade = ftTotal; })),
              ],
            ),
          ),

          // 投籃類型與 IN/OUT 控制
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: typeColors.keys.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          selected: currentType == t,
                          onSelected: (s) => setState(() => currentType = t),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                _goalToggle(true, 'IN', Colors.greenAccent),
                const SizedBox(width: 8),
                _goalToggle(false, 'OUT', Colors.redAccent),
              ],
            ),
          ),
          
          // 球場畫布
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1C27D), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[900]!, width: 4),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (d) => handleCourtTap(d.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: CourtPainter(records: List.from(shotRecords)),
                          ),
                        );
                      }
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _ftActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _goalToggle(bool isGoal, String text, Color color) {
    bool active = nextShotIsMade == isGoal;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = isGoal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color : Colors.white24, width: 2),
        ),
        child: Text(text, style: TextStyle(color: active ? color : Colors.white30, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class CourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  CourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final paintArea = Paint()..color = const Color(0xFFE67E22)..style = PaintingStyle.fill;
    final basketPaint = Paint()..color = Colors.black..style = PaintingStyle.fill;

    double midX = size.width / 2;
    double midY = size.height / 2;
    double bOffset = size.width * 0.08;

    // 球場線條
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    canvas.drawCircle(Offset(midX, midY), size.height * 0.2, linePaint);
    
    double kw = size.width * 0.18;
    double kh = size.height * 0.45;
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), paintArea);
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), linePaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), paintArea);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), linePaint);

    // 籃框標示 (黑色點)
    canvas.drawCircle(Offset(bOffset, midY), 6, basketPaint);
    canvas.drawLine(Offset(bOffset - 5, midY - 15), Offset(bOffset - 5, midY + 15), linePaint..strokeWidth = 3);
    canvas.drawCircle(Offset(size.width - bOffset, midY), 6, basketPaint);
    canvas.drawLine(Offset(size.width - bOffset + 5, midY - 15), Offset(size.width - bOffset + 5, midY + 15), linePaint);

    // 三分線
    double tr = size.height * 0.48;
    canvas.drawArc(Rect.fromCircle(center: Offset(bOffset, midY), radius: tr), -1.3, 2.6, false, linePaint..strokeWidth = 2);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - bOffset, midY), radius: tr), 1.85, 2.6, false, linePaint);

    // 投籃點
    for (var r in records) {
      final p = r.position;
      final c = r.color;
      if (r.isMade) {
        canvas.drawCircle(p, 6, Paint()..color = c);
      } else {
        canvas.drawCircle(p, 6, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawLine(Offset(p.dx-4, p.dy-4), Offset(p.dx+4, p.dy+4), Paint()..color = c..strokeWidth = 1.5);
        canvas.drawLine(Offset(p.dx+4, p.dy-4), Offset(p.dx-4, p.dy+4), Paint()..color = c..strokeWidth = 1.5);
      }
      final tp = TextPainter(text: TextSpan(text: '${r.type[0]}${r.angle.toInt()}°', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: c.withOpacity(0.8))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(p.dx + 8, p.dy - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}