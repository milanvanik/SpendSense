import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:spendsense/models/transaction_model.dart';
import 'package:spendsense/services/firestore_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _activeIndex = 1; // 0: Daily, 1: Monthly, 2: Yearly

  final List<Color> _pieChartColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Reports & Analytics",
          style: TextStyle(
            color: const Color(0xFF1B3253),
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getAllTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data."));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No data to generate reports."));
          }

          final transactions = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildTimeframeSelector(),
                SizedBox(height: 24.h),
                _buildExpensePieChartCard(transactions),
                SizedBox(height: 24.h),
                _buildIncomeVsExpenseBarChartCard(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI & DATA PROCESSING WIDGETS ---

  Widget _buildTimeframeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeFrameButton("Daily", 0),
          _buildTimeFrameButton("Monthly", 1),
          _buildTimeFrameButton("Yearly", 2),
        ],
      ),
    );
  }

  Widget _buildTimeFrameButton(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeIndex = index);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: _activeIndex == index ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            gradient: _activeIndex == index
                ? const LinearGradient(
                    colors: [Color(0xFFA9E5B7), Color(0xFF80C0E2)],
                  )
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: _activeIndex == index ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensePieChartCard(List<TransactionModel> transactions) {
    final Map<String, double> categoryExpenses = {};
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    for (var trans in transactions) {
      if (trans.type == 'expense' &&
          trans.date.toDate().month == currentMonth &&
          trans.date.toDate().year == currentYear) {
        categoryExpenses.update(
          trans.categoryName,
          (value) => value + trans.amount,
          ifAbsent: () => trans.amount,
        );
      }
    }

    if (categoryExpenses.isEmpty) {
      return const Card(
        child: ListTile(title: Text("No expenses this month.")),
      );
    }

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    categoryExpenses.forEach((category, amount) {
      sections.add(
        PieChartSectionData(
          color: _pieChartColors[colorIndex % _pieChartColors.length],
          value: amount,
          title:
              '${(amount / categoryExpenses.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Expenses by Category - This Month",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categoryExpenses.keys.map((name) {
                      final color =
                          _pieChartColors[categoryExpenses.keys
                                  .toList()
                                  .indexOf(name) %
                              _pieChartColors.length];
                      return _buildLegend(color, name);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpenseBarChartCard(
    List<TransactionModel> transactions,
  ) {
    final Map<String, Map<String, double>> monthlyTotals = {};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM').format(month);
      monthlyTotals[monthKey] = {'income': 0.0, 'expense': 0.0};
    }

    for (var trans in transactions) {
      final transMonth = DateFormat('MMM').format(trans.date.toDate());
      if (monthlyTotals.containsKey(transMonth)) {
        monthlyTotals[transMonth]!.update(
          trans.type,
          (value) => value + trans.amount,
        );
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Income vs Expenses",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: monthlyTotals.entries.map((entry) {
                    final monthIndex = monthlyTotals.keys.toList().indexOf(
                      entry.key,
                    );
                    return BarChartGroupData(
                      x: monthIndex,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['income']!,
                          color: Colors.green,
                          width: 15,
                        ),
                        BarChartRodData(
                          toY: entry.value['expense']!,
                          color: Colors.red,
                          width: 15,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            monthlyTotals.keys.toList()[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
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

  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: color),
          SizedBox(width: 8.w),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
