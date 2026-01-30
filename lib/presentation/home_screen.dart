import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spendsense/custom_widgets/overview_card.dart';
import 'package:spendsense/custom_widgets/transanction_list_item.dart';
import 'package:spendsense/models/transaction_model.dart';
import 'package:spendsense/presentation/setting_screen.dart';
import 'package:spendsense/services/firestore_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instantiate the service
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                _buildTopBar(),
                SizedBox(height: 30.h),

                // --- Live Overview Section ---
                // This StreamBuilder handles the overview card calculations
                _buildOverviewSection(),

                SizedBox(height: 40.h),
                Text(
                  "RECENT TRANSACTIONS",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B3253),
                  ),
                ),
                SizedBox(height: 20.h),

                // --- Live Recent Transactions List ---
                // This StreamBuilder handles the list of recent transactions
                _buildRecentTransactionsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- BUILDER WIDGETS ---

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "OVERVIEW",
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B3253),
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => SettingScreen()));
          },
          child: CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFF80C0E2).withOpacity(0.3),
            child: Icon(
              Icons.person_outline,
              color: const Color(0xFF1B3253),
              size: 24.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _firestoreService.getMonthlyTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading data."));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildOverviewCards(0.0, 0.0, 0.0);
        }

        // Calculate totals from the stream data
        final transactions = snapshot.data!;
        double totalIncome = 0.0;
        double totalExpenses = 0.0;

        for (var trans in transactions) {
          if (trans.type == 'income') {
            totalIncome += trans.amount;
          } else {
            totalExpenses += trans.amount;
          }
        }
        double balance = totalIncome - totalExpenses;

        return _buildOverviewCards(totalIncome, totalExpenses, balance);
      },
    );
  }

  Widget _buildOverviewCards(double income, double expenses, double balance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OverviewCard(
          label: "Total Income",
          amount: _currencyFormat.format(income),
          icon: Icons.arrow_upward,
          gradientColors: const [Color(0xFFA9E5B7), Color(0xFF6FCF97)],
        ),
        OverviewCard(
          label: "Total Expenses",
          amount: _currencyFormat.format(expenses),
          icon: Icons.arrow_downward,
          gradientColors: const [Color(0xFFF2994A), Color(0xFFEB5757)],
        ),
        OverviewCard(
          label: "Current Balance",
          amount: _currencyFormat.format(balance),
          icon: Icons.account_balance,
          gradientColors: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _firestoreService.getRecentTransactionsStream(),
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
              "No recent transactions found.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final transactions = snapshot.data!;
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return TransactionListItem(transaction: transactions[index]);
            },
            separatorBuilder: (context, index) => const Divider(),
          ),
        );
      },
    );
  }
}
