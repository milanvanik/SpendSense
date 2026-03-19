import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:spendsense/custom_widgets/transanction_list_item.dart';
import 'package:spendsense/models/transaction_model.dart';
import 'package:spendsense/services/firestore_service.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  // This is the core logic for grouping transactions by month.
  Map<String, List<TransactionModel>> _groupTransactionsByMonth(
    List<TransactionModel> transactions,
  ) {
    final Map<String, List<TransactionModel>> groupedTransactions = {};

    for (final transaction in transactions) {
      // Use DateFormat to create a unique key for each month (e.g., "October 2025")
      String monthKey = DateFormat(
        'MMMM yyyy',
      ).format(transaction.date.toDate());
      if (groupedTransactions[monthKey] == null) {
        groupedTransactions[monthKey] = [];
      }
      groupedTransactions[monthKey]!.add(transaction);
    }
    return groupedTransactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Transaction History",
          style: TextStyle(
            color: const Color(0xFF1B3253),
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list, color: Color(0xFF1B3253)),
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestoreService.getAllTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading transactions."));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No transactions found.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final transactions = snapshot.data!;
          final groupedTransactions = _groupTransactionsByMonth(transactions);
          final monthKeys = groupedTransactions.keys.toList();

          return ListView.builder(
            itemCount: monthKeys.length,
            itemBuilder: (context, index) {
              final monthKey = monthKeys[index];
              final monthlyTransactions = groupedTransactions[monthKey]!;

              // Calculate the total for this month
              double monthlyTotal = 0.0;
              for (var trans in monthlyTransactions) {
                if (trans.type == 'income') {
                  monthlyTotal += trans.amount;
                } else {
                  monthlyTotal -= trans.amount;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // This is custom month header
                  _buildMonthHeader(monthKey, monthlyTotal),

                  // This is the list of transactions for that month
                  ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: monthlyTransactions.length,
                    itemBuilder: (context, tIndex) {
                      return TransactionListItem(
                        transaction: monthlyTransactions[tIndex],
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(String monthKey, double total) {
    final isProfit = total >= 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border(
            left: BorderSide(
              color: isProfit ? Colors.green : Colors.red,
              width: 5.w,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthKey,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: const Color(0xFF1B3253),
              ),
            ),
            Text(
              "${isProfit ? '+' : ''}${_currencyFormat.format(total)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: isProfit ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
