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
    // 籃框圓心位置
    double basketX = isLeftHalf ? size.width * 0.08 : size.width * 0.92;
    double basketY = size.height / 2;

    double dx = pos.dx - basketX;
    double dy = pos.dy - basketY;

    // 角度邏輯：
    // 使用 atan2 獲取弧度。dy 是垂直距離，dx 是水平距離。
    // 在左半場，dx 為正表示往場內走；在右半場，-dx 為正表示往場內走。
    double rad = isLeftHalf ? math.atan2(dy.abs(), dx) : math.atan2(dy.abs(), -dx);
    double deg = rad * 180 / math.pi;
    
    // 轉換邏輯：
    // 當站在籃框正對面時 (dx很大, dy趨近0)，rad趨近0，我們希望顯示 90。
    // 當站在底角時 (dx趨近0, dy很大)，rad趨近 pi/2 (90度)，我們希望顯示 180。
    // 因此最終角度 = 90 + deg
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
      _updateStreak();
    });
  }

  void _updateStreak() {
    int s = 0;
    for (int i = _records.length - 1; i >= 0; i--) {
      if (_records[i].isMade) s++; else break;
    }
    _streak = s;
  }

  void _undo() {
    if (_records.isNotEmpty) {
      setState(() {
        _records.removeLast();
        _updateStreak();
        _lastAngle = _records.isEmpty ? 0.0 : _records.last.angle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = _records.length;
    int made = _records.where((r) => r.isMade).length;
    double acc = total == 0 ? 0 : (made / total) * 100;
    double ftAcc = _ftTotal == 0 ? 0 : (_ftMade / _ftTotal) * 100;
    String today = "2026 / 05 / 02";

    return Scaffold(
      body: Column(
        children: [
          // 1. 頂部狀態列
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 10),
            color: const Color(0xFF252525),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.undo, color: Colors.white), onPressed: _undo),
                    const Text('BASKETBALL TRAINER PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 48),
                  ],
                ),
                Text(today, style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // 2. 數據面板
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: const Color(0xFF252525),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox('SHOTS', total.toString(), Colors.white),
                _statBox('MADE', made.toString(), Colors.orangeAccent),
                _statBox('ACC%', '${acc.toStringAsFixed(1)}%', Colors.cyanAccent),
                _statBox('STREAK', _streak.toString(), Colors.yellowAccent),
              ],
            ),
          ),
          // 3. 罰球控制區
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: Row(
              children: [
                Text('罰球 : 投 $_ftTotal / 中 $_ftMade (${ftAcc.toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.orange, fontSize: 14)),
                const SizedBox(width: 10),
                GestureDetector(onTap: () => setState(() => _ftTotal++), child: const Icon(Icons.add_circle_outline, size: 22, color: Colors.white)),
                const SizedBox(width: 10),
                GestureDetector(onTap: () => setState(() { _ftTotal++; _ftMade++; }), child: const Icon(Icons.check_circle_outline, size: 22, color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() { _records.clear(); _ftTotal = 0; _ftMade = 0; _streak = 0; _lastAngle = 0; }),
                  child: const Icon(Icons.refresh, color: Colors.redAccent, size: 26),
                ),
              ],
            ),
          ),
          // 4. 投籃類型選擇（修正字體與擠壓問題）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: _typeColors.keys.map((type) {
                bool isSelected = _currentType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentType = type),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _typeColors[type] : Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.white : Colors.white10),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 20, // 確保字體完整清晰
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
          // 5. 角度提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(color: Colors.yellowAccent, borderRadius: BorderRadius.circular(20)),
            child: Text(
              '最後投籃角度: ${_lastAngle.toStringAsFixed(1)}° (90°為正對面)',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          // 6. IN / OUT 按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _goalBtn(true, 'IN', Colors.green),
              const SizedBox(width: 25),
              _goalBtn(false, 'OUT', Colors.grey.shade700),
            ],
          ),
          // 7. 球場繪圖區
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1C27D),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.shade900, width: 4),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (d) => _handleTap(d.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: FullCourtPainter(records: _records),
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
    );
  }

  Widget _statBox(String label, String val, Color c) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)),
    ]);
  }

  Widget _goalBtn(bool goal, String txt, Color c) {
    bool active = _nextIsMade == goal;
    return ElevatedButton(
      onPressed: () => setState(() => _nextIsMade = goal),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? (goal ? Colors.green : Colors.red) : Colors.grey[800],
        minimumSize: const Size(120, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(txt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }
}

class FullCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  FullCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    final dotPaint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    
    double w = size.width;
    double h = size.height;
    double midX = w / 2;
    double midY = h / 2;

    // 基本球場標線
    canvas.drawLine(Offset(midX, 0), Offset(midX, h), linePaint);
    canvas.drawCircle(Offset(midX, midY), h * 0.18, linePaint);

    for (bool isLeft in [true, false]) {
      double sideMul = isLeft ? 1 : -1;
      double startX = isLeft ? 0 : w;
      double keyW = w * 0.18;
      double keyH = h * 0.38;
      // 禁區
      canvas.drawRect(Rect.fromCenter(center: Offset(startX + (sideMul * keyW / 2), midY), width: keyW, height: keyH), linePaint);
      // 三分線與籃框點
      double threeR = h * 0.42;
      canvas.drawArc(Rect.fromCenter(center: Offset(startX + (w * 0.05 * sideMul), midY), width: (w * 0.3) * 2, height: threeR * 2), isLeft ? -math.pi / 2 : math.pi / 2, math.pi, false, linePaint);
    }

    // 籃框圓點
    canvas.drawCircle(Offset(w * 0.08, midY), 12, dotPaint);
    canvas.drawCircle(Offset(w * 0.92, midY), 12, dotPaint);

    // 繪製記錄點與角度文字
    for (var r in records) {
      final pPaint = Paint()..color = r.color;
      canvas.drawCircle(r.position, 8, pPaint);
      
      if (!r.isMade) {
        canvas.drawCircle(r.position, 8, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${r.angle.toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold, backgroundColor: Colors.white70),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(r.position.dx - (textPainter.width / 2), r.position.dy - 22));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}