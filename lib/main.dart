import 'package:flutter/material.dart';

void main() {
  runApp(const BasketballProApp());
}

class BasketballProApp extends StatelessWidget {
  const BasketballProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

/// 投籃紀錄資料模型
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
  // 狀態變數：完整保留所有邏輯
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 45.0;
  String currentType = '定點';
  int streak = 0;
  int maxStreak = 0;

  /// 處理球場點擊
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

  /// 完整重置功能（含對話框確認）
  void resetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置數據'),
        content: const Text('確定要清除所有投籃紀錄嗎？'),
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
            child: const Text('確定清空', style: TextStyle(color: Colors.red)),
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
        title: const Text('投籃數據分析系統', style: TextStyle(fontWeight: FontWeight.bold)),
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
          // 頂部數據看板
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.orange[800],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('總次數', total.toString(), Colors.white),
                _buildStatItem('命中', made.toString(), Colors.greenAccent[100]!),
                _buildStatItem('命中率', '${rate.toStringAsFixed(1)}%', Colors.yellowAccent),
                _buildStatItem('當前連進', streak.toString(), Colors.white),
              ],
            ),
          ),

          // 控制控制面板
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('目前角度: ${currentAngle.toInt()}°', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900])),
                    Row(
                      children: [
                        _statusButton(true, '進球', Colors.green),
                        const SizedBox(width: 8),
                        _statusButton(false, '沒進', Colors.red),
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

          // 視覺化球場區域 (修正三分線比例)
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.orange[100]!, width: 2),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: GestureDetector(
                  onTapDown: (d) => handleTap(d.localPosition),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: PerfectCourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _statusButton(bool isMade, String label, Color activeColor) {
    bool isSelected = nextShotIsMade == isMade;
    return GestureDetector(
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

/// 完美比例球場繪圖器
class PerfectCourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  PerfectCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    double cx = size.width / 2;
    double top = 40.0;

    // 1. 底線
    canvas.drawLine(Offset(0, top), Offset(size.width, top), paint);

    // 2. 禁區 - 寬度與高度比例調整
    double kw = size.width * 0.45;
    double kh = size.height * 0.4;
    canvas.drawRect(Rect.fromLTWH(cx - kw / 2, top, kw, kh), paint);

    // 3. 罰球弧
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, top + kh), width: kw, height: kw), 0, 3.14159, false, paint);

    // 4. 籃框系統
    canvas.drawCircle(Offset(cx, top + 25), 20, paint); // 籃網位置
    canvas.drawLine(Offset(cx - 35, top + 10), Offset(cx + 35, top + 10), paint); // 籃板

    // 5. 三分線 - 解決被切掉的問題
    // 使用動態計算，確保弧線半徑不會超過容器寬度
    double maxThreeRadius = (size.width / 2) * 0.88; 
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, top + 25), radius: maxThreeRadius),
      0, 3.14159, false, paint
    );
    // 補上底角兩側的垂直直線
    canvas.drawLine(Offset(cx - maxThreeRadius, top), Offset(cx - maxThreeRadius, top + 25), paint);
    canvas.drawLine(Offset(cx + maxThreeRadius, top), Offset(cx + maxThreeRadius, top + 25), paint);

    // 6. 繪製紀錄點
    for (var r in records) {
      final pPaint = Paint()..color = r.isMade ? Colors.green : Colors.red..style = PaintingStyle.fill;
      canvas.drawCircle(r.position, 10, pPaint);
      canvas.drawCircle(r.position, 10, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

      // 數據標籤
      TextPainter(
        text: TextSpan(
          text: '${r.angle.toInt()}° ${r.type}',
          style: TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold, backgroundColor: Colors.white.withOpacity(0.7)),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(r.position.dx - 10, r.position.dy + 12));
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}