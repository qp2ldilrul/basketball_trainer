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
    // 籃框中心座標
    double basketX = isLeftHalf ? size.width * 0.08 : size.width * 0.92;
    double basketY = size.height / 2;

    // 計算相對於籃框的位移
    // dx: 往場內的水平距離 (取絕對值)
    // dy: 偏離中心線的垂直距離 (取絕對值)
    double dx = isLeftHalf ? (pos.dx - basketX) : (basketX - pos.dx);
    double dy = (pos.dy - basketY).abs();

    // 角度計算：
    // 使用 atan2(垂直位移, 水平位移) 得到與中心水平線的夾角 (0~90度)
    // 當正對籃框時，dy=0, dx大 -> rad=0, 我們希望顯示 90
    // 當在底角時，dx趨近0, dy大 -> rad=pi/2, 我們希望顯示 180
    double rad = math.atan2(dy, dx);
    double deg = rad * 180 / math.pi;
    double finalAngle = 90 + deg;

    setState(() {
      _lastAngle = finalAngle;
      _records.add(ShotRecord(
        position: pos,
        isMade: _nextIsMade,
        angle: finalAngle,
        type: _currentType,
        color: _typeColors[_currentType]!,
      ));
      
      // 更新連進次數 (Streak)
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
        // 重新計算 Streak
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
        decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
        child: Column(
          children: [
            // --- 頂部標題與復原鍵 ---
            Container(
              padding: const EdgeInsets.only(top: 15, bottom: 5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.undo, color: Colors.white, size: 28),
                      onPressed: _undo,
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'BASKETBALL TRAINER PRO',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2026 / 05 / 02',
                        style: TextStyle(color: Colors.orange.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- 數據統計面板 ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('SHOTS', totalCount.toString(), Colors.white),
                  _buildStatItem('MADE', madeCount.toString(), Colors.orangeAccent),
                  _buildStatItem('ACC%', '${accuracy.toStringAsFixed(1)}%', Colors.cyanAccent),
                  _buildStatItem('STREAK', _streak.toString(), Colors.yellowAccent),
                ],
              ),
            ),
            const Divider(color: Colors.white10, thickness: 1, indent: 20, endIndent: 20),
            // --- 罰球計數區 ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  Text(
                    '罰球 : 投 $_ftTotal / 中 $_ftMade (${ftAccuracy.toStringAsFixed(1)}%)',
                    style: const TextStyle(color: Colors.orange, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () => setState(() => _ftTotal++),
                    child: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 24),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() { _ftTotal++; _ftMade++; }),
                    child: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 24),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _resetAll,
                    child: const Icon(Icons.refresh, color: Colors.redAccent, size: 28),
                  ),
                ],
              ),
            ),
            // --- 投籃類型選擇器 (平均分配空間) ---
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? _typeColors[type] : const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white12,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 22,
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
            // --- 角度即時顯示 (修正 FontWeight) ---
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE101),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                '最後投籃角度: ${_lastAngle.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.black, 
                  fontWeight: FontWeight.w900, // 修正處：使用有效權重
                  fontSize: 17
                ),
              ),
            ),
            // --- IN / OUT 按鈕 ---
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLargeActionBtn(true),
                  const SizedBox(width: 30),
                  _buildLargeActionBtn(false),
                ],
              ),
            ),
            // --- 球場繪製區域 ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1C27D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBF8C4A), width: 5),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLargeActionBtn(bool isIn) {
    bool isSelected = _nextIsMade == isIn;
    Color btnColor = isIn ? const Color(0xFF4CAF50) : const Color(0xFF424242);
    if (!isSelected) btnColor = const Color(0xFF333333);

    return InkWell(
      onTap: () => setState(() => _nextIsMade = isIn),
      child: Container(
        width: 130,
        height: 55,
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
        ),
        child: Center(
          child: Text(
            isIn ? 'IN' : 'OUT',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
      ..strokeWidth = 2.5;

    final Paint fillPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    double w = size.width;
    double h = size.height;
    double midX = w / 2;
    double midY = h / 2;

    // 球場中線
    canvas.drawLine(Offset(midX, 0), Offset(midX, h), linePaint);
    // 中圈
    canvas.drawCircle(Offset(midX, midY), h * 0.18, linePaint);

    // 左右半場繪製
    for (bool isLeft in [true, false]) {
      double startX = isLeft ? 0 : w;
      double multiplier = isLeft ? 1 : -1;

      // 禁區 (Key)
      double keyWidth = w * 0.18;
      double keyHeight = h * 0.35;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(startX + (keyWidth / 2 * multiplier), midY), width: keyWidth, height: keyHeight),
        linePaint,
      );

      // 三分線 (3-Point Line)
      double threeRadius = h * 0.42;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(startX + (w * 0.05 * multiplier), midY), width: w * 0.6, height: threeRadius * 2),
        isLeft ? -math.pi / 2 : math.pi / 2,
        math.pi,
        false,
        linePaint,
      );

      // 籃框圓點
      canvas.drawCircle(Offset(isLeft ? w * 0.08 : w * 0.92, midY), 10, fillPaint);
    }

    // 繪製投籃點與角度標籤
    for (var record in records) {
      final Paint pPaint = Paint()..color = record.color;
      canvas.drawCircle(record.position, 8, pPaint);

      if (!record.isMade) {
        canvas.drawCircle(record.position, 8, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
      }

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '${record.angle.toStringAsFixed(1)}°',
          style: const TextStyle(
            color: Colors.black, 
            fontSize: 13, 
            fontWeight: FontWeight.bold, 
            backgroundColor: Colors.white70
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(record.position.dx - (tp.width / 2), record.position.dy - 24));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}