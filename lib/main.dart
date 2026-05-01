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
        primarySwatch: Colors.orange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
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
  
  // 畫布比例切換
  double selectedAspectRatio = 16 / 9;

  final Map<String, Color> typeColors = {
    '定點': Colors.cyanAccent,
    '跳投': Colors.purpleAccent,
    '運球': Colors.amberAccent,
    '上籃': Colors.greenAccent,
    '勾射': Colors.orangeAccent,
  };

  void handleTap(Offset localPosition, Size boxSize) {
    // 以左側籃框為圓心計算角度 (cx=0 附近)
    double cx = 30.0; 
    double cy = boxSize.height / 2;
    double dx = localPosition.dx - cx;
    double dy = localPosition.dy - cy;
    
    double radians = math.atan2(dy, dx);
    double degrees = radians * 180 / math.pi;

    setState(() {
      currentAngle = degrees.abs();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('PRO COURT ANALYTICS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.undo, color: Colors.orangeAccent), onPressed: () => setState(() { if(shotRecords.isNotEmpty) shotRecords.removeLast(); })),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.redAccent), onPressed: () => setState(() { shotRecords.clear(); streak = 0; })),
        ],
      ),
      body: Column(
        children: [
          // 頂部數據列
          _buildTopDashboard(),

          // 比例與手機尺寸切換
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  const Text('尺寸:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  _ratioChip(16 / 9, '16:9 (橫)'),
                  _ratioChip(4 / 3, '4:3 (iPad)'),
                  _ratioChip(1 / 1, '1:1'),
                  _ratioChip(9 / 16, '9:16 (手機)'),
                  _ratioChip(9 / 19.5, 'iPhone(全)'),
                ],
              ),
            ),
          ),

          // 動作控制區
          _buildActionControls(),

          // 橫向全場球場
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: AspectRatio(
                  aspectRatio: selectedAspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5B567), // 模擬木地板顏色
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[800]!, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTapDown: (details) => handleTap(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTopDashboard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF252525),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('SHOTS', shotRecords.length.toString(), Colors.white),
          _statItem('MADE', shotRecords.where((r) => r.isMade).length.toString(), Colors.orangeAccent),
          _statItem('STREAK', streak.toString(), Colors.yellowAccent),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _buildActionControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: typeColors.keys.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: ChoiceChip(
                    label: Text(type, style: const TextStyle(fontSize: 12)),
                    selected: currentType == type,
                    onSelected: (s) => setState(() => currentType = type),
                    selectedColor: typeColors[type]!.withOpacity(0.4),
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _goalButton(true),
          const SizedBox(width: 5),
          _goalButton(false),
        ],
      ),
    );
  }

  Widget _goalButton(bool isMade) {
    bool active = nextShotIsMade == isMade;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = isMade),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? (isMade ? Colors.green : Colors.red) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isMade ? Colors.green : Colors.red),
        ),
        child: Text(isMade ? 'IN' : 'OUT', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _ratioChip(double ratio, String label) {
    bool isSelected = selectedAspectRatio == ratio;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        backgroundColor: isSelected ? Colors.orangeAccent : Colors.transparent,
        onPressed: () => setState(() => selectedAspectRatio = ratio),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.orangeAccent : Colors.white24)),
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
      ..strokeWidth = 2.0;

    final areaPaint = Paint()
      ..color = Colors.orange[700]!
      ..style = PaintingStyle.fill;

    double midX = size.width / 2;
    double midY = size.height / 2;

    // 1. 繪製全場樣式
    // 中線
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    // 中圈
    canvas.drawCircle(Offset(midX, midY), size.height * 0.15, linePaint);
    
    // 繪製兩側禁區 (橘色填滿，如圖所示)
    double kw = size.width * 0.18;
    double kh = size.height * 0.4;
    // 左側禁區
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), areaPaint);
    canvas.drawRect(Rect.fromLTWH(0, midY - kh/2, kw, kh), linePaint);
    // 右側禁區
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), areaPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, midY - kh/2, kw, kh), linePaint);

    // 三分線 (圓弧)
    double tr = size.height * 0.45;
    canvas.drawArc(Rect.fromCircle(center: Offset(30, midY), radius: tr), -math.pi/2, math.pi, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - 30, midY), radius: tr), math.pi/2, math.pi, false, linePaint);

    // 2. 繪製紀錄點位
    for (var r in records) {
      final p = r.position;
      final Color c = r.color;

      if (r.isMade) {
        // 進球：發光點
        canvas.drawCircle(p, 6, Paint()..color = c);
        canvas.drawCircle(p, 10, Paint()..color = c.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      } else {
        // 沒進：空心 X
        canvas.drawCircle(p, 6, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawLine(Offset(p.dx-4, p.dy-4), Offset(p.dx+4, p.dy+4), Paint()..color = c..strokeWidth = 2);
        canvas.drawLine(Offset(p.dx+4, p.dy-4), Offset(p.dx-4, p.dy+4), Paint()..color = c..strokeWidth = 2);
      }

      // 繪製 類型+角度 標籤
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${r.type[0]}${r.angle.toInt()}°',
          style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold, 
            backgroundColor: c.withOpacity(0.7)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(p.dx + 8, p.dy - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}