import 'package:flutter/material.dart';
import 'dart:math' as math;

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
        primarySwatch: Colors.cyan,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
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
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 90.0;
  String currentType = '定點';
  int streak = 0;

  final Map<String, Color> typeColors = {
    '定點': Colors.cyanAccent,
    '跳投': Colors.purpleAccent,
    '運球': Colors.amberAccent,
    '上籃': Colors.greenAccent,
    '勾射': Colors.orangeAccent,
  };

  void handleTap(Offset localPosition, Size boxSize) {
    double cx = boxSize.width / 2;
    double basketY = 30.0 + 15.0; 
    double dx = localPosition.dx - cx;
    double dy = localPosition.dy - basketY;
    
    double radians = math.atan2(dy, dx);
    double degrees = radians * 180 / math.pi;
    if (degrees < 0) degrees = 0;

    setState(() {
      currentAngle = degrees;
      shotRecords.add(ShotRecord(
        position: localPosition,
        isMade: nextShotIsMade,
        angle: currentAngle,
        type: currentType,
        color: typeColors[currentType]!,
      ));
      _recalculateStreak();
    });
  }

  void undoLastAction() {
    if (shotRecords.isNotEmpty) {
      setState(() {
        shotRecords.removeLast();
        _recalculateStreak();
      });
    }
  }

  void _recalculateStreak() {
    int currentStreak = 0;
    for (int i = shotRecords.length - 1; i >= 0; i--) {
      if (shotRecords[i].isMade) {
        currentStreak++;
      } else {
        break;
      }
    }
    streak = currentStreak;
  }

  void resetData() {
    setState(() {
      shotRecords.clear();
      streak = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalShots = shotRecords.length;
    int totalMade = shotRecords.where((r) => r.isMade).length;
    double shootingPercentage = totalShots == 0 ? 0 : (totalMade / totalShots) * 100;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.cyanAccent),
          onPressed: shotRecords.isEmpty ? null : undoLastAction,
        ),
        title: const Text('SHOT ANALYTICS PRO', 
          style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.pinkAccent), onPressed: resetData),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTechStat('TOTAL', totalShots.toString(), Colors.white),
                _buildTechStat('MADE', totalMade.toString(), Colors.cyanAccent),
                _buildTechStat('ACC %', '${shootingPercentage.toStringAsFixed(1)}', Colors.yellowAccent),
                _buildTechStat('STREAK', streak.toString(), Colors.orangeAccent),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ANGLE: ${currentAngle.toInt()}°', 
                      style: TextStyle(color: typeColors[currentType], fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        _statusButton(true, 'GOAL'),
                        const SizedBox(width: 10),
                        _statusButton(false, 'MISS'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: typeColors.keys.map((type) {
                      bool isSelected = currentType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) => setState(() => currentType = type),
                          selectedColor: typeColors[type]!.withOpacity(0.3),
                          labelStyle: TextStyle(color: isSelected ? typeColors[type] : Colors.white60),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: GestureDetector(
                      onTapDown: (details) => handleTap(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: AnalyticsPainter(records: List.from(shotRecords)),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 10)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _statusButton(bool isMade, String text) {
    bool selected = nextShotIsMade == isMade;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = isMade),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.white : Colors.white24, width: 2),
        ),
        child: Text(text, style: TextStyle(color: selected ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class AnalyticsPainter extends CustomPainter {
  final List<ShotRecord> records;
  AnalyticsPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueGrey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    double cx = size.width / 2;
    double top = 30.0;

    // 繪製球場背景線
    canvas.drawLine(Offset(0, top), Offset(size.width, top), linePaint);
    canvas.drawRect(Rect.fromLTWH(cx - size.width * 0.16, top, size.width * 0.32, size.height * 0.35), linePaint);
    canvas.drawCircle(Offset(cx, top + 15), 15, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, top + 15), radius: size.width * 0.42), 0, math.pi, false, linePaint);

    // 繪製每一個紀錄點及其標籤
    for (var r in records) {
      final Color shotColor = r.color;
      
      // 1. 繪製點位
      if (r.isMade) {
        canvas.drawCircle(r.position, 6, Paint()..color = shotColor);
        canvas.drawCircle(r.position, 10, Paint()..color = shotColor.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      } else {
        canvas.drawCircle(r.position, 6, Paint()..color = shotColor..style = PaintingStyle.stroke..strokeWidth = 2);
        final p = r.position;
        canvas.drawLine(Offset(p.dx-3, p.dy-3), Offset(p.dx+3, p.dy+3), Paint()..color = shotColor..strokeWidth = 1.5);
        canvas.drawLine(Offset(p.dx+3, p.dy-3), Offset(p.dx-3, p.dy+3), Paint()..color = shotColor..strokeWidth = 1.5);
      }

      // 2. 關鍵修正：繪製文字標籤 (如：定65°)
      // 使用 TextPainter 確保文字能被正確渲染在 CustomPaint 上
      final textSpan = TextSpan(
        text: '${r.type[0]}${r.angle.toInt()}°',
        style: TextStyle(
          color: shotColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          // 加上深色發光效果，確保在深背景下清晰
          shadows: const [
            Shadow(blurRadius: 4.0, color: Colors.black, offset: Offset(1.0, 1.0)),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      
      // 將文字繪製在點位右上方稍微偏移一點的位置
      textPainter.paint(canvas, Offset(r.position.dx + 8, r.position.dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant AnalyticsPainter oldDelegate) {
    // 每次紀錄點數量不同時，強迫重繪
    return oldDelegate.records.length != records.length;
  }
}