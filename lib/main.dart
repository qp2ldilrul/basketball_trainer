import 'package:flutter/material.dart';

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
  final String type;
  final Color color;

  ShotRecord({
    required this.position,
    required this.isMade,
    required this.type,
    required this.color,
  });
}

class ShotProScreen extends StatefulWidget {
  const ShotProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ShotTrackerBody(),
    );
  }
}

class ShotTrackerBody extends StatefulWidget {
  const ShotTrackerBody({super.key});

  @override
  State<ShotTrackerBody> createState() => _ShotTrackerBodyState();
}

class _ShotTrackerBodyState extends State<ShotTrackerBody> {
  final List<ShotRecord> _records = [];
  bool _nextIsMade = true;
  String _currentType = '定點';
  int _streak = 0;
  int _ftTotal = 0;
  int _ftMade = 0;

  final Map<String, Color> _typeColors = {
    '定點': Colors.cyanAccent,
    '跳投': Colors.purpleAccent,
    '運球': Colors.yellowAccent,
    '上籃': Colors.limeAccent,
    '勾射': Colors.orangeAccent,
  };

  void _handleTap(Offset pos) {
    setState(() {
      _records.add(ShotRecord(
        position: pos,
        isMade: _nextIsMade,
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

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('罰球：', style: TextStyle(color: Colors.orangeAccent, fontSize: 16)),
              Text('投 $_ftTotal / 中 $_ftMade (${ftAcc.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _ftTotal++)),
              IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: () => setState(() { _ftTotal++; _ftMade++; })),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.redAccent), onPressed: () => setState(() { _records.clear(); _streak = 0; _ftTotal = 0; _ftMade = 0; })),
            ],
          ),
        ),
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
                onSelected: (val) => setState(() => _currentType = type),
              ),
            )).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _goalBtn(true, 'IN', Colors.green),
              const SizedBox(width: 20),
              _goalBtn(false, 'OUT', Colors.red),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1C27D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade800, width: 4),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (d) => _handleTap(d.localPosition),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: SimpleCourtPainter(records: _records),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String val, Color c) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)),
    ]);
  }

  Widget _goalBtn(bool goal, String txt, Color c) {
    bool active = _nextIsMade == goal;
    return ElevatedButton(
      onPressed: () => setState(() => _nextIsMade = goal),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? c : Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: Text(txt, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class SimpleCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  SimpleCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final dotPaint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    
    double midX = size.width / 2;
    double midY = size.height / 2;

    // 畫中線與禁區線條
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), linePaint);
    canvas.drawCircle(Offset(midX, midY), 50, linePaint);
    
    // 左右兩邊中線位置的大黑點
    canvas.drawCircle(Offset(size.width * 0.08, midY), 12, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.92, midY), 12, dotPaint);

    // 畫投籃點
    for (var r in records) {
      final pPaint = Paint()..color = r.color;
      if (r.isMade) {
        canvas.drawCircle(r.position, 8, pPaint);
      } else {
        canvas.drawCircle(r.position, 8, pPaint..style = PaintingStyle.stroke..strokeWidth = 3);
        canvas.drawLine(Offset(r.position.dx-5, r.position.dy-5), Offset(r.position.dx+5, r.position.dy+5), pPaint);
        canvas.drawLine(Offset(r.position.dx+5, r.position.dy-5), Offset(r.position.dx-5, r.position.dy+5), pPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}