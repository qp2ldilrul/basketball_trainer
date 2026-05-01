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
  double _currentAngle = 0.0;
  String _currentType = '定點';
  int _streak = 0;
  int _ftTotal = 0;
  int _ftMade = 0;

  final Map<String, Color> _typeColors = {
    '定點': Colors.cyanAccent,      
    '跳投': Colors.magentaAccent,   
    '運球': Colors.yellowAccent,    
    '上籃': Colors.limeAccent,      
    '勾射': Colors.orangeAccent,    
  };

  void _handleTap(Offset pos, Size size) {
    double bx = size.width * 0.08;
    double by = size.height * 0.5;
    double targetX = pos.dx > size.width / 2 ? size.width - bx : bx;
    double dx = pos.dx - targetX;
    double dy = pos.dy - by;
    double deg = (math.atan2(dy, dx) * 180 / math.pi).abs();

    setState(() {
      _currentAngle = deg;
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
          
          // 罰球與類型選擇
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('罰球: '),
                ActionChip(label: Text('$_ftMade/$_ftTotal'), onPressed: () => setState(() => _ftTotal++)),
                IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => setState((){_ftTotal++; _ftMade++;})),
              ],
            ),
          ),

          Wrap(
            spacing: 8,
            children: _typeColors.keys.map((type) => ChoiceChip(
              label: Text(type),
              selected: _currentType == type,
              selectedColor: _typeColors[type],
              onSelected: (s) => setState(() => _currentType = type),
            )).toList(),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _nextIsMade = true),
                  style: ElevatedButton.styleFrom(backgroundColor: _nextIsMade ? Colors.green : Colors.grey),
                  child: const Text('IN'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => setState(() => _nextIsMade = false),
                  style: ElevatedButton.styleFrom(backgroundColor: !_nextIsMade ? Colors.red : Colors.grey),
                  child: const Text('OUT'),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: const Color(0xFFF1C27D),
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
      Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c)),
    ]);
  }
}

class WebCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  WebCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0;
    double mx = size.width / 2;
    double my = size.height / 2;
    
    // 繪製球場
    canvas.drawLine(Offset(mx, 0), Offset(mx, size.height), paint);
    canvas.drawCircle(Offset(mx, my), 40, paint);
    
    // 籃框標記
    canvas.drawCircle(Offset(size.width * 0.08, my), 10, paint..color = Colors.red);
    canvas.drawCircle(Offset(size.width * 0.92, my), 10, paint);

    for (var r in records) {
      final pPaint = Paint()..color = r.color;
      if (r.isMade) {
        canvas.drawCircle(r.position, 6, pPaint);
      } else {
        canvas.drawCircle(r.position, 6, pPaint..style = PaintingStyle.stroke);
      }

      final textSpan = TextSpan(
        text: '${r.type[0]}${r.angle.toInt()}°',
        style: TextStyle(color: Colors.black, fontSize: 10, backgroundColor: r.color.withOpacity(0.7)),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, r.position + const Offset(8, -10));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}