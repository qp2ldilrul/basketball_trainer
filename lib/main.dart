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
  String _currentType = '定點';
  int _streak = 0;
  int _ftTotal = 0;
  int _ftMade = 0;

  // 五種投籃方式高對比色
  final Map<String, Color> _typeColors = {
    '定點': Colors.cyanAccent,      
    '跳投': Colors.magentaAccent,   
    '運球': Colors.yellowAccent,    
    '上籃': Colors.limeAccent,      
    '勾射': Colors.orangeAccent,    
  };

  void _handleTap(Offset pos, Size size) {
    // 定位左側籃框中心
    double bx = size.width * 0.08;
    double by = size.height * 0.5;
    
    // 若點擊右半邊，則以右側籃框為基準計算角度
    double targetX = pos.dx > size.width / 2 ? size.width - bx : bx;
    double dx = pos.dx - targetX;
    double dy = pos.dy - by;
    double deg = (math.atan2(dy, dx) * 180 / math.pi).abs();

    setState(() {
      _records.add(ShotRecord(
        position: pos,
        isMade: _nextIsMade,
        angle: deg,
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

  @override
  Widget build(BuildContext context) {
    int total = _records.length;
    int made = _records.where((r) => r.isMade).length;
    double acc = total == 0 ? 0 : (made / total) * 100;
    double ftAcc = _ftTotal == 0 ? 0 : (_ftMade / _ftTotal) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('PRO COURT ANALYTICS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: () => setState(() {
              _records.clear(); _streak = 0; _ftTotal = 0; _ftMade = 0;
            }),
          )
        ],
      ),
      body: Column(
        children: [
          // 上方數據看板
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF252525),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statBox('SHOTS', total.toString(), Colors.white),
                _statBox('ACC%', '${acc.toStringAsFixed(1)}%', Colors.cyanAccent),
                _statBox('STREAK', _streak.toString(), Colors.yellowAccent),
              ],
            ),
          ),
          
          // 罰球計算區
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('罰球: ', style: TextStyle(color: Colors.orangeAccent)),
                Text('$_ftMade / $_ftTotal (${ftAcc.toStringAsFixed(1)}%)'),
                const SizedBox(width: 10),
                _ftBtn(Icons.add, () => setState(() => _ftTotal++)),
                _ftBtn(Icons.check, () => setState(() { _ftTotal++; _ftMade++; })),
              ],
            ),
          ),

          // 投籃類型選擇
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _typeColors.keys.map((type) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(type),
                  selected: _currentType == type,
                  selectedColor: _typeColors[type],
                  labelStyle: TextStyle(color: _currentType == type ? Colors.black : Colors.white),
                  onSelected: (s) => setState(() => _currentType = type),
                ),
              )).toList(),
            ),
          ),

          // 進球切換按鈕
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _goalBtn(true, 'IN', Colors.green),
                const SizedBox(width: 20),
                _goalBtn(false, 'OUT', Colors.red),
              ],
            ),
          ),

          // 球場繪圖區
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1C27D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.brown, width: 2),
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
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c)),
    ]);
  }

  Widget _ftBtn(IconData icon, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, size: 20), onPressed: onTap);
  }

  Widget _goalBtn(bool goal, String txt, Color c) {
    bool active = _nextIsMade == goal;
    return ElevatedButton(
      onPressed: () => setState(() => _nextIsMade = goal),
      style: ElevatedButton.styleFrom(backgroundColor: active ? c : Colors.grey[800]),
      child: Text(txt),
    );
  }
}

class FullCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  FullCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final boardPaint = Paint()..color = Colors.white..strokeWidth = 3.0;
    final rimPaint = Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2.0;
    
    double mx = size.width / 2;
    double my = size.height / 2;

    // 基本場地線
    canvas.drawLine(Offset(mx, 0), Offset(mx, size.height), linePaint);
    canvas.drawCircle(Offset(mx, my), 40, linePaint);
    
    // 左側籃板籃圈
    canvas.drawLine(Offset(size.width * 0.04, my - 25), Offset(size.width * 0.04, my + 25), boardPaint);
    canvas.drawCircle(Offset(size.width * 0.08, my), 8, rimPaint);

    // 右側籃板籃圈
    canvas.drawLine(Offset(size.width * 0.96, my - 25), Offset(size.width * 0.96, my + 25), boardPaint);
    canvas.drawCircle(Offset(size.width * 0.92, my), 8, rimPaint);

    for (var r in records) {
      final pPaint = Paint()..color = r.color;
      
      // 繪製點位
      if (r.isMade) {
        canvas.drawCircle(r.position, 6, pPaint..style = PaintingStyle.fill);
      } else {
        canvas.drawCircle(r.position, 6, pPaint..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawLine(Offset(r.position.dx - 4, r.position.dy - 4), Offset(r.position.dx + 4, r.position.dy + 4), pPaint);
        canvas.drawLine(Offset(r.position.dx + 4, r.position.dy - 4), Offset(r.position.dx - 4, r.position.dy + 4), pPaint);
      }

      // 繪製文字標籤 (類型 + 角度)
      final textSpan = TextSpan(
        text: '${r.type[0]}${r.angle.toInt()}°',
        style: TextStyle(
          color: Colors.black, 
          fontSize: 9, 
          fontWeight: FontWeight.bold,
          backgroundColor: r.color.withOpacity(0.8)
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, r.position + const Offset(8, -12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}