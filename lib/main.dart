import 'package:flutter/material.dart';

void main() => runApp(const BasketballProApp());

class BasketballProApp extends StatelessWidget {
  const BasketballProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        fontFamily: 'sans-serif',
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
  ShotRecord({
    required this.position, 
    required this.isMade, 
    required this.angle, 
    required this.type
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
  double currentAngle = 45.0;
  String currentType = '定點';
  int streak = 0;
  int maxStreak = 0;

  void handleTap(Offset pos) {
    setState(() {
      shotRecords.add(ShotRecord(
        position: pos,
        isMade: nextShotIsMade,
        angle: currentAngle,
        type: currentType,
      ));
      
      // 更新連進紀錄
      if (nextShotIsMade) {
        streak++;
        if (streak > maxStreak) maxStreak = streak;
      } else {
        streak = 0;
      }
    });
  }

  void resetRecords() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確定重置？'),
        content: const Text('這將會清除目前所有的投籃紀錄。'),
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
            child: const Text('確定', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalShots = shotRecords.length;
    int madeShots = shotRecords.where((r) => r.isMade).length;
    double rate = totalShots == 0 ? 0 : (madeShots / totalShots) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('大兒子投籃數據分析系統', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[400],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep), 
            onPressed: resetRecords,
            tooltip: '重置數據',
          )
        ],
      ),
      body: Column(
        children: [
          // 頂部數據統計區
          Container(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('總投籃', totalShots.toString(), Colors.black87),
                    _buildStatItem('命中', madeShots.toString(), Colors.green),
                    _buildStatItem('命中率', '${rate.toStringAsFixed(1)}%', Colors.orange[900]!),
                    _buildStatItem('當前連進', streak.toString(), Colors.redAccent),
                  ],
                ),
              ),
            ),
          ),

          // 核心控制面板
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                // 角度滑桿區
                Row(
                  children: [
                    const Icon(Icons.architecture, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '設定角度: ${currentAngle.toInt()}°', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)
                    ),
                    const Spacer(),
                    // 進/沒進 切換按鈕
                    _buildShotStatusButton(true, '進球', Colors.green),
                    const SizedBox(width: 8),
                    _buildShotStatusButton(false, '沒進', Colors.red),
                  ],
                ),
                Slider(
                  value: currentAngle,
                  min: 0,
                  max: 90,
                  divisions: 90,
                  activeColor: Colors.orange,
                  label: '${currentAngle.toInt()}°',
                  onChanged: (v) => setState(() => currentAngle = v),
                ),
                
                // 投籃類型選擇
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['定點', '跳投', '運球', '上籃'].map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: currentType == type,
                          selectedColor: Colors.orange[200],
                          onSelected: (selected) {
                            if (selected) setState(() => currentType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 球場畫布區 (放大比例修正)
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(15, 10, 15, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                ],
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: GestureDetector(
                onTapDown: (details) => handleTap(details.localPosition),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('※ 點擊上方球場區域即可自動紀錄點位', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)
        ),
      ],
    );
  }

  Widget _buildShotStatusButton(bool status, String label, Color color) {
    bool isSelected = nextShotIsMade == status;
    return ElevatedButton(
      onPressed: () => setState(() => nextShotIsMade = status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        elevation: isSelected ? 4 : 0,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(60, 30),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}

class CourtPainter extends CustomPainter {
  final List<ShotRecord> records;
  CourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 籃框核心位置 (置頂中央)
    final rimCenter = Offset(size.width / 2, size.height * 0.12);

    // 1. 繪製籃框 (比例加大)
    canvas.drawCircle(rimCenter, size.width * 0.05, linePaint);
    
    // 2. 繪製籃板線
    canvas.drawLine(
      Offset(size.width / 2 - size.width * 0.12, size.height * 0.08),
      Offset(size.width / 2 + size.width * 0.12, size.height * 0.08),
      linePaint
    );

    // 3. 繪製禁區 (長方形比例修正)
    final keyWidth = size.width * 0.38;
    final keyHeight = size.height * 0.32;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.24), 
        width: keyWidth, 
        height: keyHeight
      ),
      linePaint
    );

    // 4. 繪製專業三分線 (寬大的半圓弧)
    // 使用寬度的 85% 作為半徑，確保弧線能漂亮地撐開整個畫布空間
    canvas.drawArc(
      Rect.fromCircle(center: rimCenter, radius: size.width * 0.85),
      0,
      3.14159, // 180度
      false,
      linePaint
    );

    // 5. 繪製所有投籃紀錄點
    for (var record in records) {
      final shotPaint = Paint()
        ..color = record.isMade 
            ? Colors.green.withOpacity(0.75) 
            : Colors.red.withOpacity(0.75)
        ..style = PaintingStyle.fill;
      
      // 點位圓圈
      canvas.drawCircle(record.position, 10, shotPaint);

      // 點位下方的角度與類型標籤
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${record.angle.toInt()}°\n${record.type}',
          style: const TextStyle(
            color: Colors.black87, 
            fontSize: 9, 
            fontWeight: FontWeight.bold,
            height: 1.2
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas, 
        Offset(record.position.dx - textPainter.width / 2, record.position.dy + 12)
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}