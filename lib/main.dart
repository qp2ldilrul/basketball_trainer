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
  final Offset position; // 歸一化座標 (0~1)
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
  const ShotProScreen({super.override});

  @override
  State<ShotProScreen> createState() => _ShotProScreenState();
}

class _ShotProScreenState extends State<ShotProScreen> {
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 0.0;
  String currentType = '定點';
  int streak = 0;
  double selectedAspectRatio = 16 / 9; // 預設橫向比例

  final Map<String, Color> typeColors = {
    '定點': Colors.cyanAccent,
    '跳投': Colors.purpleAccent,
    '運球': Colors.amberAccent,
    '上籃': Colors.greenAccent,
    '勾射': Colors.orangeAccent,
  };

  void handleTap(Offset localPosition, Size boxSize) {
    HapticFeedback.mediumImpact(); // 點擊震動感
    
    // 計算歸一化座標
    double nx = localPosition.dx / boxSize.width;
    double ny = localPosition.dy / boxSize.height;

    // 計算角度 (以左側籃框中心點約 10%, 50% 為基準)
    double basketX = boxSize.width * 0.1;
    double basketY = boxSize.height * 0.5;
    double dx = localPosition.dx - basketX;
    double dy = localPosition.dy - basketY;
    double degrees = math.atan2(dy, dx) * 180 / math.pi;

    setState(() {
      currentAngle = degrees.abs();
      shotRecords.add(ShotRecord(
        position: Offset(nx, ny),
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
            const Text('PRO SHOT ANALYTICS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(today, style: const TextStyle(fontSize: 10, color: Colors.orangeAccent)),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.undo), onPressed: () => setState(() { if(shotRecords.isNotEmpty) shotRecords.removeLast(); _updateStreak(); })),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.redAccent), onPressed: () => setState(() { shotRecords.clear(); streak = 0; })),
        ],
      ),
      body: Column(
        children: [
          _buildStatsRow(),
          _buildRatioSelector(),
          _buildControls(),
          
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: AspectRatio(
                  aspectRatio: selectedAspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3D299), // 淺木地板底色
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.brown[700]!, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (d) => handleTap(d.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: HandDrawnCourtPainter(records: List.from(shotRecords)),
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
    int made = shotRecords.where((r) => r.isMade).length;
    double acc = shotRecords.isEmpty ? 0 : (made / shotRecords.length) * 100;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFF252525),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('TOTAL', shotRecords.length.toString(), Colors.white),
          _statCol('ACC%', '${acc.toStringAsFixed(1)}%', Colors.cyanAccent),
          _statCol('STREAK', streak.toString(), Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _statCol(String l, String v, Color c) {
    return Column(children: [
      Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
    ]);
  }

  Widget _buildRatioSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const SizedBox(width: 10),
            _ratioBtn(16 / 9, '橫向 16:9'),
            _ratioBtn(4 / 3, 'iPad 4:3'),
            _ratioBtn(9 / 16, '手機 9:16'),
            _ratioBtn(1 / 1, '1:1'),
          ],
        ),
      ),
    );
  }

  Widget _ratioBtn(double r, String n) {
    bool s = selectedAspectRatio == r;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(n, style: const TextStyle(fontSize: 10)),
        selected: s,
        onSelected: (val) => setState(() => selectedAspectRatio = r),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: typeColors.keys.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: ChoiceChip(
                    label: Text(t, style: const TextStyle(fontSize: 11)),
                    selected: currentType == t,
                    onSelected: (s) => setState(() => currentType = t),
                  ),
                )).toList(),
              ),
            ),
          ),
          _goalBtn(true, 'GOAL', Colors.green),
          const SizedBox(width: 5),
          _goalBtn(false, 'MISS', Colors.red),
        ],
      ),
    );
  }

  Widget _goalBtn(bool m, String l, Color c) {
    bool a = nextShotIsMade == m;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: a ? c.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: a ? c : Colors.white24),
        ),
        child: Text(l, style: TextStyle(color: a ? c : Colors.white30, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class HandDrawnCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  HandDrawnCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final paintAreaPaint = Paint()
      ..color = const Color(0xFFE67E22) // 實心橘色禁區
      ..style = PaintingStyle.fill;

    double midX = size.width / 2;
    double midY = size.height / 2;

    // 1. 繪製全場樣式 (橫向)
    // 中線與中圈
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    canvas.drawCircle(Offset(midX, midY), size.height * 0.18, linePaint);
    
    // 兩側禁區 (強制實心橘)
    double kw = size.width * 0.18;
    double kh = size.height * 0.45;
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), paintAreaPaint);
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), linePaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), paintAreaPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), linePaint);

    // 三分線 (圓弧)
    double tr = size.height * 0.48;
    canvas.drawArc(Rect.fromCircle(center: Offset(20, midY), radius: tr), -math.pi/2, math.pi, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - 20, midY), radius: tr), math.pi/2, math.pi, false, linePaint);

    // 2. 繪製點位標籤 (類型+角度)
    for (var r in records) {
      final pos = Offset(r.position.dx * size.width, r.position.dy * size.height);
      final c = r.color;

      if (r.isMade) {
        canvas.drawCircle(pos, 6, Paint()..color = c);
        canvas.drawCircle(pos, 12, Paint()..color = c.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      } else {
        canvas.drawCircle(pos, 6, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawLine(Offset(pos.dx-4, pos.dy-4), Offset(pos.dx+4, pos.dy+4), Paint()..color = c..strokeWidth = 2.5);
        canvas.drawLine(Offset(pos.dx+4, pos.dy-4), Offset(pos.dx-4, pos.dy+4), Paint()..color = c..strokeWidth = 2.5);
      }

      // 文字標籤：類型 + 角度
      final tp = TextPainter(
        text: TextSpan(
          text: '${r.type[0]}${r.angle.toInt()}°',
          style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: c.withOpacity(0.8)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx + 10, pos.dy - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}