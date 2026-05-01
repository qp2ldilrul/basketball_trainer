import 'package:flutter/material.dart';

void main() {
  runApp(const BasketballProApp());
}

class BasketballProApp extends StatelessWidget {
  const BasketballProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 標題已移除大兒子標籤
      title: '投籃數據分析系統',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const ShotProScreen(),
    );
  }
}

/// 投籃紀錄資料模型，保存所有原始數據
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
  // 狀態變數
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 45.0;
  String currentType = '定點';
  int streak = 0;
  int maxStreak = 0;

  /// 處理球場點擊，保存數據並計算連進次數
  void handleTap(Offset localPosition) {
    setState(() {
      shotRecords.add(ShotRecord(
        position: localPosition,
        isMade: nextShotIsMade,
        angle: currentAngle,
        type: currentType,
      ));

      if (nextShotIsMade) {
        streak++;
        if (streak > maxStreak) {
          maxStreak = streak;
        }
      } else {
        streak = 0;
      }
    });
  }

  /// 清除當前所有統計數據
  void resetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置紀錄'),
        content: const Text('確定要清除目前的投籃數據嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              setState(() {
                shotRecords.clear();
                streak = 0;
                maxStreak = 0;
              });
              Navigator.pop(ctx);
            },
            child: const Text('確定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int total = shotRecords.length;
    int made = shotRecords.where((r) => r.isMade).length;
    double rate = total == 0 ? 0 : (made / total) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        // 標題確認修改：去掉「大兒子」
        title: const Text('投籃數據分析系統', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        centerTitle: true,
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: resetData),
        ],
      ),
      body: Column(
        children: [
          // 頂部儀表板
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.orange[800],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('總次數', total.toString(), Colors.white),
                _buildStat('命中', made.toString(), Colors.greenAccent[100]!),
                _buildStat('命中率', '${rate.toStringAsFixed(1)}%', Colors.yellowAccent),
                _buildStat('當前連進', streak.toString(), Colors.white),
              ],
            ),
          ),

          // 控制面板
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('目前角度: ${currentAngle.toInt()}°', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900])),
                    Row(
                      children: [
                        _statusToggle(true, '進球', Colors.green),
                        const SizedBox(width: 8),
                        _statusToggle(false, '沒進', Colors.red),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: currentAngle,
                  min: 0, max: 90, divisions: 90,
                  activeColor: Colors.orange,
                  label: '${currentAngle.toInt()}°',
                  onChanged: (v) => setState(() => currentAngle = v),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['定點', '跳投', '運球', '上籃', '勾射'].map((t) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(t),
                        selected: currentType == t,
                        selectedColor: Colors.orange[100],
                        onSelected: (s) => setState(() => currentType = t),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 視覺化球場區域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.orange[100]!, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: GestureDetector(
                  onTapDown: (d) => handleTap(d.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: ProfessionalCourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: Text('※ 點擊上方白區模擬投籃點', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String l, String v, Color c) => Column(
    children: [
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 5),
      Text(v, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _statusToggle(bool isMade, String label, Color activeColor) {
    bool isSelected = nextShotIsMade == isMade;
    return InkWell(
      onTap: () => setState(() => nextShotIsMade = isMade),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// 專業版繪圖器 - 重新設計三分線與比例
class ProfessionalCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  ProfessionalCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final dashPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double cx = size.width / 2;
    double topPadding = 40.0;

    // 1. 底線
    canvas.drawLine(Offset(0, topPadding), Offset(size.width, topPadding), linePaint);

    // 2. 禁區 (The Key) - 修正比例
    double kWidth = size.width * 0.45;
    double kHeight = size.height * 0.42;
    canvas.drawRect(Rect.fromLTWH(cx - kWidth / 2, topPadding, kWidth, kHeight), linePaint);

    // 3. 罰球弧 (全圓)
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, topPadding + kHeight), width: kWidth, height: kWidth), 0, 3.14159, false, linePaint);
    
    // 4. 籃框系統 (籃板、籃圈)
    canvas.drawLine(Offset(cx - 35, topPadding + 10), Offset(cx + 35, topPadding + 10), linePaint); // 籃板
    canvas.drawCircle(Offset(cx, topPadding + 25), 20, linePaint); // 籃圈

    // 5. 三分線 (大弧度擴散)
    double threeRadius = size.width * 0.85;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, topPadding + 25), radius: threeRadius),
      0.3, 2.54, false, linePaint
    );

    // 6. 繪製所有投籃點
    for (var r in records) {
      // 點的外圈
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(r.position + const Offset(1, 2), 11, shadowPaint);

      // 點的核心
      final pointPaint = Paint()
        ..color = r.isMade ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(r.position, 10, pointPaint);

      // 點的白框
      canvas.drawCircle(r.position, 10, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

      // 標註文字
      TextPainter(
        text: TextSpan(
          text: '${r.angle.toInt()}° ${r.type}',
          style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold, backgroundColor: Colors.white.withOpacity(0.8)),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(r.position.dx - 12, r.position.dy + 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}