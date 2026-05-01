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
  // 核心數據
  final List<ShotRecord> _records = [];
  bool _nextIsMade = true;
  double _currentAngle = 0.0;
  String _currentType = '定點';
  int _streak = 0;

  // 罰球數據
  int _ftTotal = 0;
  int _ftMade = 0;

  final Map<String, Color> _typeColors = {
    '定點': Colors.cyanAccent,
    '跳投': Colors.purpleAccent,
    '運球': Colors.amberAccent,
    '上籃': Colors.greenAccent,
    '勾射': Colors.orangeAccent,
  };

  void _handleTap(Offset pos, Size size) {
    // 以籃框位置 (8%) 為原點計算角度
    double bx = size.width * 0.08;
    double by = size.height * 0.5;
    double dx = pos.dx - bx;
    double dy = pos.dy - by;
    double deg = math.atan2(dy, dx) * 180 / math.pi;

    setState(() {
      _currentAngle = deg.abs();
      _records.add(ShotRecord(
        position: pos,
        isMade: _nextIsMade,
        angle: _currentAngle,
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
    final now = DateTime.now();
    final dateStr = "${now.year} / ${now.month.toString().padLeft(2, '0')} / ${now.day.toString().padLeft(2, '0')}";
    
    int total = _records.length;
    int made = _records.where((r) => r.isMade).length;
    double acc = total == 0 ? 0 : (made / total) * 100;
    double ftAcc = _ftTotal == 0 ? 0 : (_ftMade / _ftTotal) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Column(
          children: [
            const Text('PRO COURT ANALYTICS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.orangeAccent)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.undo),
          onPressed: () => setState(() {
            if (_records.isNotEmpty) _records.removeLast();
            _updateStreak();
          }),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
            onPressed: () => setState(() {
              _records.clear();
              _streak = 0;
              _ftTotal = 0;
              _ftMade = 0;
            }),
          )
        ],
      ),
      body: Column(
        children: [
          // 數據面板
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
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

          // 罰球控制
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('罰球：', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  Expanded(child: Text('投 $_ftTotal / 中 $_ftMade (${ftAcc.toStringAsFixed(1)}%)')),
                  _circleBtn(Icons.add, Colors.grey, () => setState(() => _ftTotal++)),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.sports_basketball, Colors.orangeAccent, () => setState(() { _ftTotal++; _ftMade++; })),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.remove, Colors.redAccent, () => setState(() { if(_ftTotal > 0) _ftTotal--; if(_ftMade > _ftTotal) _ftMade = _ftTotal; })),
                ],
              ),
            ),
          ),

          // 類型與命中切換
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _typeColors.keys.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: ChoiceChip(
                          label: Text(type, style: const TextStyle(fontSize: 11)),
                          selected: _currentType == type,
                          onSelected: (s) => setState(() => _currentType = type),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                _toggleGoal(true, 'IN', Colors.greenAccent),
                const SizedBox(width: 5),
                _toggleGoal(false, 'OUT', Colors.redAccent),
              ],
            ),
          ),

          // 球場區域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1C27D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[900]!, width: 4),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (d) => _handleTap(d.localPosition, Size(constraints.maxWidth, constraints.maxHeight)),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: WebCourtPainter(records: _records),
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
      Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
    ]);
  }

  Widget _circleBtn(IconData icon, Color c, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c)),
        child: Icon(icon, size: 16, color: c),
      ),
    );
  }

  Widget _toggleGoal(bool goal, String txt, Color c) {
    bool active = _nextIsMade == goal;
    return GestureDetector(
      onTap: () => setState(() => _nextIsMade = goal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? c : Colors.white24, width: 2),
        ),
        child: Text(txt, style: TextStyle(color: active ? c : Colors.white38, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

class WebCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  WebCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final paintArea = Paint()..color = const Color(0xFFE67E22)..style = PaintingStyle.fill;
    
    double mx = size.width / 2;
    double my = size.height / 2;
    double bx = size.width * 0.08;

    // 線條繪製
    canvas.drawLine(Offset(mx, 0), Offset(mx, size.height), linePaint);
    canvas.drawCircle(Offset(mx, my), size.height * 0.2, linePaint);
    
    double kw = size.width * 0.18;
    double kh = size.height * 0.45;
    canvas.drawRect(Rect.fromLTWH(0, my - kh/2, kw, kh), paintArea);
    canvas.drawRect(Rect.fromLTWH(0, my - kh/2, kw, kh), linePaint);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, my - kh/2, kw, kh), paintArea);
    canvas.drawRect(Rect.fromLTWH(size.width - kw, my - kh/2, kw, kh), linePaint);

    // 三分線
    double tr = size.height * 0.48;
    canvas.drawArc(Rect.fromCircle(center: Offset(bx, my), radius: tr), -1.3, 2.6, false, linePaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width - bx, my), radius: tr), 1.85, 2.6, false, linePaint);

    // 投籃點
    for (var r in records) {
      final p = r.position;
      if (r.isMade) {
        canvas.drawCircle(p, 6, Paint()..color = r.color);
      } else {
        canvas.drawCircle(p, 6, Paint()..color = r.color..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawLine(Offset(p.dx-4, p.dy-4), Offset(p.dx+4, p.dy+4), Paint()..color = r.color);
        canvas.drawLine(Offset(p.dx+4, p.dy-4), Offset(p.dx-4, p.dy+4), Paint()..color = r.color);
      }
    }
  }

  @override
  bool shouldRepaint(WebCourtPainter oldDelegate) => true;
}