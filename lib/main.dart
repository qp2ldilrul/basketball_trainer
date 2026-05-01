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
      title: 'BASKETBALL TRAINER PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF9800),
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
  final List<ShotRecord> _records = [];
  bool _nextIsMade = true;
  String _currentType = '定';
  int _streak = 0;
  int _ftTotal = 0;
  int _ftMade = 0;
  double _lastAngle = 0.0;

  final Map<String, Color> _typeColors = {
    '定': Colors.cyanAccent,
    '跳': Colors.purpleAccent,
    '運': Colors.yellowAccent,
    '上': Colors.limeAccent,
    '勾': Colors.orangeAccent,
  };

  void _handleTap(Offset pos, Size size) {
    bool isLeftHalf = pos.dx < size.width / 2;
    // 籃框中心座標 (嚴格依照視覺比例對齊)
    double basketX = isLeftHalf ? size.width * 0.08 : size.width * 0.92;
    double basketY = size.height / 2;

    // 計算水平與垂直位移
    double dx = isLeftHalf ? (pos.dx - basketX) : (basketX - pos.dx);
    double dy = (pos.dy - basketY).abs();

    // 角度計算：
    // 正對籃框 dy=0 -> 90.0度
    // 底線底角 dx=0 -> 180.0度
    double rad = math.atan2(dy, dx);
    double deg = rad * 180 / math.pi;
    double finalAngle = 90.0 + deg;

    setState(() {
      _lastAngle = finalAngle;
      _records.add(ShotRecord(
        position: pos,
        isMade: _nextIsMade,
        angle: finalAngle,
        type: _currentType,
        color: _typeColors[_currentType]!,
      ));
      
      // 計算連進次數
      int currentStreak = 0;
      for (int i = _records.length - 1; i >= 0; i--) {
        if (_records[i].isMade) {
          currentStreak++;
        } else {
          break;
        }
      }
      _streak = currentStreak;
    });
  }

  void _undo() {
    if (_records.isNotEmpty) {
      setState(() {
        _records.removeLast();
        int currentStreak = 0;
        for (int i = _records.length - 1; i >= 0; i--) {
          if (_records[i].isMade) {
            currentStreak++;
          } else {
            break;
          }
        }
        _streak = currentStreak;
        _lastAngle = _records.isEmpty ? 0.0 : _records.last.angle;
      });
    }
  }

  void _resetAll() {
    setState(() {
      _records.clear();
      _ftTotal = 0;
      _ftMade = 0;
      _streak = 0;
      _lastAngle = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalCount = _records.length;
    int madeCount = _records.where((r) => r.isMade).length;
    double accuracy = totalCount == 0 ? 0.0 : (madeCount / totalCount) * 100;
    double ftAccuracy = _ftTotal == 0 ? 0.0 : (_ftMade / _ftTotal) * 100;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
        child: Column(
          children: [
            // --- 標題與復原按鈕 ---
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.undo, color: Colors.white, size: 30),
                      onPressed: _undo,
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'BASKETBALL TRAINER PRO',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 20,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '2026 / 05 / 02',
                        style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- 數據統計區 (含陰影細節) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('SHOTS', totalCount.toString(), Colors.white),
                  _buildStatItem('MADE', madeCount.toString(), Colors.orangeAccent),
                  _buildStatItem('ACC%', '${accuracy.toStringAsFixed(1)}%', Colors.cyanAccent),
                  _buildStatItem('STREAK', _streak.toString(), Colors.yellowAccent),
                ],
              ),
            ),
            // --- 罰球控制列 ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '罰球 : 投 $_ftTotal / 中 $_ftMade (${ftAccuracy.toStringAsFixed(1)}%)',
                    style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 15),
                  InkWell(onTap: () => setState(() => _ftTotal++), child: const Icon(Icons.add_circle_outline, size: 28, color: Colors.white70)),
                  const SizedBox(width: 15),
                  InkWell(onTap: () => setState(() { _ftTotal++; _ftMade++; }), child: const Icon(Icons.check_circle_outline, size: 28, color: Colors.white70)),
                  const Spacer(),
                  InkWell(onTap: _resetAll, child: const Icon(Icons.refresh, color: Colors.redAccent, size: 32)),
                ],
              ),
            ),
            // --- 投籃類型選擇器 (完整寬度與裝飾) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: _typeColors.keys.map((type) {
                  bool isSelected = _currentType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentType = type),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? _typeColors[type] : const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.white : Colors.white12, width: 2.5),
                          boxShadow: isSelected ? [BoxShadow(color: _typeColors[type]!.withOpacity(0.5), blurRadius: 10)] : null,
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // --- 角度即時顯示 (嚴格使用 FontWeight.w900) ---
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE101),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2))],
              ),
              child: Text(
                '最後投籃角度: ${_lastAngle.toStringAsFixed(1)}°',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
            // --- IN / OUT 大按鈕 ---
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLargeActionBtn(true, 'IN', const Color(0xFF4CAF50)),
                  const SizedBox(width: 40),
                  _buildLargeActionBtn(false, 'OUT', const Color(0xFF424242)),
                ],
              ),
            ),
            // --- 球場區域 (包含所有標線細節) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1C27D),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFBF8C4A), width: 6),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 3)],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (details) => _handleTap(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: BasketballCourtPainter(records: _records),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLargeActionBtn(bool isIn, String label, Color baseColor) {
    bool isSelected = _nextIsMade == isIn;
    return InkWell(
      onTap: () => setState(() => _nextIsMade = isIn),
      child: Container(
        width: 150,
        height: 65,
        decoration: BoxDecoration(
          color: isSelected ? baseColor : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
          boxShadow: isSelected ? [BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 8)] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class BasketballCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  BasketballCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final Paint basketPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;

    double w = size.width;
    double h = size.height;
    double midX = w / 2;
    double midY = h / 2;

    // 1. 球場中線與中圈
    canvas.drawLine(Offset(midX, 0), Offset(midX, h), linePaint);
    canvas.drawCircle(Offset(midX, midY), h * 0.16, linePaint);

    // 2. 左右半場繪製 (嚴格對齊標線)
    for (bool isLeft in [true, false]) {
      double startX = isLeft ? 0 : w;
      double side = isLeft ? 1 : -1;

      // 禁區 (還原截圖比例)
      double kWidth = w * 0.16;
      double kHeight = h * 0.35;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(startX + (kWidth / 2 * side), midY), width: kWidth, height: kHeight),
        linePaint,
      );

      // 三分線弧度 (還原截圖比例，確保底角有空間)
      double threeRadius = h * 0.42;
      canvas.drawArc(
        Rect.fromLTWH(isLeft ? -w * 0.12 : w * 0.72, midY - threeRadius, w * 0.4, threeRadius * 2),
        isLeft ? -math.pi / 2 : math.pi / 2,
        math.pi,
        false,
        linePaint,
      );

      // 籃框點 (視覺焦點)
      canvas.drawCircle(Offset(isLeft ? w * 0.08 : w * 0.92, midY), 10, basketPaint);
    }

    // 3. 繪製所有投籃點與角度標籤
    for (var r in records) {
      final Paint pPaint = Paint()..color = r.color;
      canvas.drawCircle(r.position, 9, pPaint);
      
      if (!r.isMade) {
        canvas.drawCircle(r.position, 9, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
      }

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '${r.angle.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: Colors.black, 
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            backgroundColor: Colors.white70
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(r.position.dx - (tp.width / 2), r.position.dy - 25));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}