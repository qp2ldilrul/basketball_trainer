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
        fontFamily: 'sans-serif',
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
  // 數據統計狀態
  List<ShotRecord> shotRecords = [];
  bool nextShotIsMade = true;
  double currentAngle = 45.0;
  String currentType = '定點';
  int streak = 0;
  int maxStreak = 0;

  /// 處理點擊球場事件
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

  /// 清除所有數據
  void resetData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確定清除？'),
        content: const Text('這將會刪除本次所有的投籃紀錄與連進數據。'),
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
    int totalShots = shotRecords.length;
    int madeShots = shotRecords.where((r) => r.isMade).length;
    double successRate = totalShots == 0 ? 0 : (madeShots / totalShots) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          '投籃數據分析系統',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: resetData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 頂部統計數據看板
          Container(
            padding: const EdgeInsets.all(12.0),
            color: Colors.orange[700],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('總投籃', totalShots.toString(), Colors.white),
                _buildStatColumn('命中', madeShots.toString(), Colors.greenAccent),
                _buildStatColumn('命中率', '${successRate.toStringAsFixed(1)}%', Colors.yellowAccent),
                _buildStatColumn('當前連進', streak.toString(), Colors.white),
              ],
            ),
          ),

          // 操作面板
          Container(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '設定角度: ${currentAngle.toInt()}°',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800]),
                    ),
                    Row(
                      children: [
                        _buildStatusToggle(true, '進球'),
                        const SizedBox(width: 10),
                        _buildStatusToggle(false, '沒進'),
                      ],
                    ),
                  ],
                ),
                Slider(
                  value: currentAngle,
                  min: 0,
                  max: 90,
                  divisions: 90,
                  activeColor: Colors.orange,
                  label: '${currentAngle.toInt()}°',
                  onChanged: (value) => setState(() => currentAngle = value),
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['定點', '跳投', '運球', '上籃'].map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: currentType == type,
                          selectedColor: Colors.orange[100],
                          labelStyle: TextStyle(
                            color: currentType == type ? Colors.orange[900] : Colors.black54,
                            fontWeight: currentType == type ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool selected) {
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

          // 球場點擊區域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTapDown: (details) => handleTap(details.localPosition),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: BasketballCourtPainter(records: shotRecords),
                  ),
                ),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('💡 點擊下方球場位置即可記錄投籃點', 
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusToggle(bool isMade, String label) {
    bool isSelected = nextShotIsMade == isMade;
    return GestureDetector(
      onTap: () => setState(() => nextShotIsMade = isMade),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isMade ? Colors.green : Colors.red) 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 專業半場繪圖器 - 修正比例版本
class BasketballCourtPainter extends CustomPainter {
  final List<ShotRecord> records;

  BasketballCourtPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fillPaint = Paint()
      ..color = Colors.grey[50]!
      ..style = PaintingStyle.fill;

    // 1. 繪製籃框與底線背景
    // 籃框中心點設在頂部中央
    double centerX = size.width / 2;
    double startY = 40; // 距離頂部的距離
    
    // 2. 繪製禁區 (The Key)
    // 寬度比例設為螢幕的 40%
    double keyWidth = size.width * 0.44;
    double keyHeight = size.height * 0.38;
    Rect keyRect = Rect.fromLTWH(centerX - keyWidth / 2, startY, keyWidth, keyHeight);
    
    canvas.drawRect(keyRect, fillPaint);
    canvas.drawRect(keyRect, linePaint);

    // 3. 繪製罰球弧
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX, startY + keyHeight), width: keyWidth, height: keyWidth),
      0,
      3.14159,
      false,
      linePaint,
    );

    // 4. 繪製籃圈
    canvas.drawCircle(Offset(centerX, startY + 15), 18, linePaint);
    // 籃板
    canvas.drawLine(Offset(centerX - 35, startY), Offset(centerX + 35, startY), linePaint);

    // 5. 繪製三分線 (核心修正)
    // 使用 Path 來精確控制三分線，使其呈現大半圓形
    final threePointPath = Path();
    double threePointRadius = size.width * 0.85; // 讓弧線撐開
    
    // 定義三分線的圓弧範圍
    Rect threePointRect = Rect.fromCircle(
      center: Offset(centerX, startY + 15), 
      radius: threePointRadius
    );

    canvas.drawArc(
      threePointRect,
      0.2, // 起始角度
      2.74, // 掃過角度 (接近半圓)
      false,
      linePaint,
    );

    // 6. 繪製投籃紀錄點
    for (var record in records) {
      final pointPaint = Paint()
        ..color = record.isMade 
            ? Colors.green.withOpacity(0.85) 
            : Colors.red.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      // 畫圓點
      canvas.drawCircle(record.position, 12, pointPaint);
      
      // 畫白邊讓點更明顯
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(record.position, 12, borderPaint);

      // 顯示該點的角度與類型
      TextPainter(
        text: TextSpan(
          text: '${record.angle.toInt()}°\n${record.type}',
          style: const TextStyle(
            color: Colors.black87, 
            fontSize: 10, 
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white70
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(record.position.dx - 10, record.position.dy + 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}