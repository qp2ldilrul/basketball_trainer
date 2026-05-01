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
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy / MM / dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text('PRO COURT ANALYTICS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text(today, style: const TextStyle(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.undo), onPressed: undoLastShot),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.redAccent), onPressed: resetAll),
        ],
      ),
      body: Column(
        children: [
          _buildStatsRow(),
          _buildFreeThrowSection(), // 獨立罰球點擊區塊
          _buildShotControls(),
          
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1C27D), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[900]!, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
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

  // --- 狀態管理 ---
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 0.0;
  String currentType = '定點';
  int streak = 0;

  // 獨立罰球變數
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
    HapticFeedback.mediumImpact();
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
    setState(() => streak = s);
  }

  void undoLastShot() {
    setState(() {
      if(shotRecords.isNotEmpty) shotRecords.removeLast();
      _updateStreak();
    });
  }

  void resetAll() {
    setState(() {
      shotRecords.clear();
      streak = 0;
      ftTotal = 0;
      ftMade = 0;
    });
  }

  // --- UI 元件 ---

  Widget _buildStatsRow() {
    int made = shotRecords.where((r) => r.isMade).length;
    double acc = shotRecords.isEmpty ? 0 : (made / shotRecords.length) * 100;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF252525),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('FIELD SHOTS', shotRecords.length.toString(), Colors.white),
          _statCol('ACC%', '${acc.toStringAsFixed(1)}%', Colors.cyanAccent),
          _statCol('STREAK', streak.toString(), Colors.yellowAccent),
        ],
      ),
    );
  }

  // 獨立的罰球區塊
  Widget _buildFreeThrowSection() {
    double ftAcc = ftTotal == 0 ? 0 : (ftMade / ftTotal) * 100;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('罰球數據:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
          const SizedBox(width: 15),
          Expanded(child: Text('投 $ftTotal / 中 $ftMade (${ftAcc.toStringAsFixed(1)}%)', style: const TextStyle(fontFamily: 'monospace'))),
          // 增加總投球數
          _ftButton(icon: Icons.add, color: Colors.grey, onTap: () => setState(() => ftTotal++)),
          const SizedBox(width: 8),
          // 增加進球數 (進球時總數也會同步增加)
          _ftButton(icon: Icons.sports_basketball, color: Colors.orangeAccent, onTap: () => setState(() { ftTotal++; ftMade++; })),
          const SizedBox(width: 8),
          // 倒扣按鈕 (修正點錯時)
          _ftButton(icon: Icons.remove, color: Colors.redAccent.withOpacity(0.5), onTap: () => setState(() { if(ftTotal > 0) ftTotal--; if(ftMade > ftTotal) ftMade = ftTotal; })),
        ],
      ),
    );
  }

  Widget _ftButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(5), border: Border.all(color: color)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildShotControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: typeColors.keys.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    selected: currentType == t,
                    onSelected: (s) => setState(() => currentType = t),
                  ),
                )).toList(),
              ),
            ),
          ),
          _goalBtn(true, 'GOAL', Colors.greenAccent),
          const SizedBox(width: 8),
          _goalBtn(false, 'MISS', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _goalBtn(bool m, String l, Color c) {
    bool a = nextShotIsMade == m;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: a ? c.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: a ? c : Colors.white24, width: 2),
        ),
        child: Text(l, style: TextStyle(color: a ? c : Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _statCol(String l, String v, Color c) {
    return Column(children: [
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
    ]);
  }
}

class ProfessionalCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  ProfessionalCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white.withOpacity(0.9)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final paintAreaPaint = Paint()..color = const Color(0xFFE67E22)..style = PaintingStyle.fill;
    final basketPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;

    double midX = size.width / 2;
    double midY = size.height / 2;
    double basketOffset = size.width * 0.08;

    // 1. 球場底色與禁區
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    canvas.drawCircle(Offset(midX, midY), size.height * 0.2, linePaint);
    
    double kw = size.width * 0.18;
    double kh = size.height * 0.45;
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), paintAreaPaint);
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), linePaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), paintAreaPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), linePaint);

    // 2. 籃框標記
    canvas.drawCircle(Offset(basketOffset, midY), 6, basketPaint);
    canvas.drawLine(Offset(basketOffset - 5, midY - 15), Offset(basketOffset - 5, midY + 15), linePaint..strokeWidth = 3);
    canvas.drawCircle(Offset(size.width - basketOffset, midY), 6, basketPaint);
    canvas.drawLine(Offset(size.width - basketOffset + 5, midY - 15), Offset(size.width - basketOffset + 5, midY + 15), linePaint);

    // 3. 三分線
    double tr = size.height * 0.48;
    canvas.drawArc(Rect.fromCircle(center: Offset(basketOffset, midY), radius: tr), -1.3, 2.6, false, linePaint..strokeWidth = 2);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - basketOffset, midY), radius: tr), 1.85, 2.6, false, linePaint);

    // 4. 繪製球場投籃點
    for (var r in records) {
      final pos = r.position;
      final c = r.color;
      if (r.isMade) {
        canvas.drawCircle(pos, 7, Paint()..color = c);
      } else {
        canvas.drawCircle(pos, 7, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2.5);
        canvas.drawLine(Offset(pos.dx-5, pos.dy-5), Offset(pos.dx+5, pos.dy+5), Paint()..color = c..strokeWidth = 2);
        canvas.drawLine(Offset(pos.dx+5, pos.dy-5), Offset(pos.dx-5, pos.dy+5), Paint()..color = c..strokeWidth = 2);
      }
      final tp = TextPainter(text: TextSpan(text: '${r.type[0]}${r.angle.toInt()}°', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold, backgroundColor: c.withOpacity(0.85))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(pos.dx + 12, pos.dy - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}