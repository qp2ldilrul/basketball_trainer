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
  double currentAngle = 90.0; // 預設中間 90 度
  String currentType = '定點';
  int streak = 0;

  // 核心邏輯：點擊球場並自動計算角度
  void handleTap(Offset localPosition, Size boxSize) {
    // 籃框中心點座標 (需與畫筆邏輯一致)
    double cx = boxSize.width / 2;
    double basketY = 30.0 + 15.0; 

    // 計算點擊位置相對於籃框的角度 (弧度轉角度)
    // dy 是點擊點 y 減去籃框 y，dx 是點擊點 x 減去籃框 x
    double dx = localPosition.dx - cx;
    double dy = localPosition.dy - basketY;
    
    // 使用 atan2 取得角度 (範圍 -PI 到 PI)，轉換為 0-180 度
    double radians = math.atan2(dy, dx);
    double degrees = radians * 180 / math.pi;
    
    // 調整角度基準：讓籃框正下方為 90 度，左側趨近 180，右側趨近 0
    double finalAngle = degrees; 
    if (finalAngle < 0) finalAngle = 0; // 防止負數

    setState(() {
      currentAngle = finalAngle; // 即時更新顯示的角度
      shotRecords.add(ShotRecord(
        position: localPosition,
        isMade: nextShotIsMade,
        angle: currentAngle,
        type: currentType,
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
          // 數據面板
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

          // 控制區 (角度顯示與狀態切換)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 這裡的角度會隨著點擊球場自動跳動
                    Text('DETECTED: ${currentAngle.toInt()}°', 
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        _techToggleButton(true, 'GOAL'),
                        const SizedBox(width: 10),
                        _techToggleButton(false, 'MISS'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['定點', '跳投', '運球', '上籃', '勾射'].map((t) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(t),
                        selected: currentType == t,
                        selectedColor: Colors.cyanAccent.withOpacity(0.2),
                        onSelected: (s) => setState(() => currentType = t),
                        checkmarkColor: Colors.cyanAccent,
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 核心球場區
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: GestureDetector(
                      // 點擊即觸發位置紀錄與角度計算
                      onTapDown: (details) => handleTap(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: TechCourtPainter(records: shotRecords),
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
        Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, 
          fontFamily: 'monospace', shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)])),
      ],
    );
  }

  Widget _techToggleButton(bool isMade, String text) {
    bool selected = nextShotIsMade == isMade;
    Color activeColor = isMade ? Colors.cyanAccent : Colors.pinkAccent;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = isMade),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? activeColor : Colors.blueGrey[700]!, width: 2),
        ),
        child: Text(text, style: TextStyle(
          color: selected ? activeColor : Colors.blueGrey[400], 
          fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}

class TechCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  TechCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueGrey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double cx = size.width / 2;
    double top = 30.0;

    // 底線
    canvas.drawLine(Offset(0, top), Offset(size.width, top), linePaint);
    
    // 禁區
    double kw = size.width * 0.32;
    double kh = size.height * 0.35;
    canvas.drawRect(Rect.fromLTWH(cx - kw / 2, top, kw, kh), linePaint);
    
    // 罰球弧
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, top + kh), width: kw, height: kw), 0, 3.14, false, linePaint);

    // 籃框
    canvas.drawCircle(Offset(cx, top + 15), 15, linePaint..color = Colors.cyanAccent.withOpacity(0.5));

    // 三分線
    double tr = size.width * 0.42;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, top + 15), radius: tr), 0, 3.14, false, linePaint);
    canvas.drawLine(Offset(cx - tr, top), Offset(cx - tr, top + 15), linePaint);
    canvas.drawLine(Offset(cx + tr, top), Offset(cx + tr, top + 15), linePaint);

    // 繪製投球點
    for (var r in records) {
      final color = r.isMade ? Colors.cyanAccent : Colors.pinkAccent;
      canvas.drawCircle(r.position, 10, Paint()..color = color.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(r.position, 5, Paint()..color = color);
      canvas.drawCircle(r.position, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}