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
  // --- 狀態數據 ---
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 0.0;
  String currentType = '定點';
  int streak = 0;

  // 獨立罰球數據
  int ftTotal = 0;
  int ftMade = 0;

  final Map<String, Color> typeColors = {
    '定點': Colors.cyanAccent,
    '跳投': Colors.purpleAccent,
    '運球': Colors.amberAccent,
    '上籃': Colors.greenAccent,
    '勾射': Colors.orangeAccent,
  };

  // --- 邏輯處理 ---
  void handleCourtTap(Offset localPosition, Size boxSize) {
    HapticFeedback.mediumImpact();
    // 以籃框位置 (約 8%) 為中心計算
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
      _updateStreak();
    });
  }

  void _updateStreak() {
    int s = 0;
    for (var i = shotRecords.length - 1; i >= 0; i--) {
      if (shotRecords[i].isMade) s++; else break;
    }
    streak = s;
  }

  void resetAll() {
    setState(() {
      shotRecords.clear();
      streak = 0;
      ftTotal = 0;
      ftMade = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy / MM / dd').format(DateTime.now());

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
            _updateStreak();
          })
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.redAccent), onPressed: resetAll),
        ],
      ),
      body: Column(
        children: [
          _buildStatsRow(),        // 頂部完整計數器
          _buildFreeThrowSection(), // 罰球獨立區塊
          _buildActionControls(),   // 投籃控制項
          
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1C27D), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[900]!, width: 4),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (d) => handleCourtTap(d.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: ProfessionalCourtPainter(records: List.from(shotRecords)),
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

  Widget _buildStatsRow() {
    int total = shotRecords.length;
    int made = shotRecords.where((r) => r.isMade).length;
    double acc = total == 0 ? 0 : (made / total) * 100;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF252525),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('SHOTS', total.toString(), Colors.white),
          _statItem('MADE', made.toString(), Colors.orangeAccent),
          _statItem('ACC%', '${acc.toStringAsFixed(1)}%', Colors.cyanAccent),
          _statItem('STREAK', streak.toString(), Colors.yellowAccent),
        ],
      ),
    );
  }

  Widget _buildFreeThrowSection() {
    double ftAcc = ftTotal == 0 ? 0 : (ftMade / ftTotal) * 100;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('罰球：', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          Expanded(child: Text('投 $ftTotal / 中 $ftMade (${ftAcc.toStringAsFixed(1)}%)')),
          _ftSmallBtn(Icons.add, Colors.grey, () => setState(() => ftTotal++)),
          const SizedBox(width: 8),
          _ftSmallBtn(Icons.sports_basketball, Colors.orangeAccent, () => setState(() { ftTotal++; ftMade++; })),
          const SizedBox(width: 8),
          _ftSmallBtn(Icons.remove, Colors.redAccent.withOpacity(0.5), () => setState(() { if(ftTotal > 0) ftTotal--; if(ftMade > ftTotal) ftMade = ftTotal; })),
        ],
      ),
    );
  }

  Widget _ftSmallBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildActionControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
          _toggleGoalBtn(true, 'IN', Colors.greenAccent),
          const SizedBox(width: 6),
          _toggleGoalBtn(false, 'OUT', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _toggleGoalBtn(bool m, String l, Color c) {
    bool active = nextShotIsMade == m;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? c : Colors.white24),
        ),
        child: Text(l, style: TextStyle(color: active ? c : Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}

class ProfessionalCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  ProfessionalCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final paintAreaPaint = Paint()..color = const Color(0xFFE67E22)..style = PaintingStyle.fill;
    final basketPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;

    double midX = size.width / 2;
    double midY = size.height / 2;
    double basketOffset = size.width * 0.08;

    // 1. 中線與中圈
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    canvas.drawCircle(Offset(midX, midY), size.height * 0.2, linePaint);
    
    // 2. 兩側禁區
    double kw = size.width * 0.18;
    double kh = size.height * 0.45;
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), paintAreaPaint);
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), linePaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), paintAreaPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), linePaint);

    // 3. 籃框標記與籃板
    canvas.drawCircle(Offset(basketOffset, midY), 6, basketPaint);
    canvas.drawLine(Offset(basketOffset - 5, midY - 15), Offset(basketOffset - 5, midY + 15), linePaint..strokeWidth = 3);
    canvas.drawCircle(Offset(size.width - basketOffset, midY), 6, basketPaint);
    canvas.drawLine(Offset(size.width - basketOffset + 5, midY - 15), Offset(size.width - basketOffset + 5, midY + 15), linePaint);

    // 4. 三分線
    double tr = size.height * 0.48;
    canvas.drawArc(Rect.fromCircle(center: Offset(basketOffset, midY), radius: tr), -1.3, 2.6, false, linePaint..strokeWidth = 2);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - basketOffset, midY), radius: tr), 1.85, 2.6, false, linePaint);

    // 5. 繪製紀錄點
    for (var r in records) {
      final pos = r.position;
      final c = r.color;
      if (r.isMade) {
        canvas.drawCircle(pos, 6, Paint()..color = c);
      } else {
        canvas.drawCircle(pos, 6, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawLine(Offset(pos.dx-4, pos.dy-4), Offset(pos.dx+4, pos.dy+4), Paint()..color = c..strokeWidth = 1.5);
        canvas.drawLine(Offset(pos.dx+4, pos.dy-4), Offset(pos.dx-4, pos.dy+4), Paint()..color = c..strokeWidth = 1.5);
      }
      final tp = TextPainter(text: TextSpan(text: '${r.type[0]}${r.angle.toInt()}°', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: c.withOpacity(0.8))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(pos.dx + 8, pos.dy - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}