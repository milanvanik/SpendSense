import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spendsense/custom_widgets/common_auth_button.dart';
import 'package:intl/intl.dart';
import 'package:spendsense/models/categories.dart';
import 'package:spendsense/models/transaction_model.dart';
import 'package:spendsense/services/firestore_service.dart';
import 'package:spendsense/utils/appconstant.dart';

class AddNewTransaction extends StatefulWidget {
  const AddNewTransaction({super.key});

  @override
  State<AddNewTransaction> createState() => _AddNewTransactionState();
}

class _AddNewTransactionState extends State<AddNewTransaction> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  String _transactionType = 'expense';

  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _firestoreService.getCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSaveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Appconstant.showSnackBar(
        context,
        message: "You are not logged in.",
        isSuccess: false,
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      Appconstant.showSnackBar(
        context,
        message: "Please enter a valid amount.",
        isSuccess: false,
      );
      return;
    }

    final newTransaction = TransactionModel(
      type: _transactionType,
      amount: amount,
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      date: Timestamp.fromDate(_selectedDate),
      description: _descriptionController.text.trim(),
      userId: user.uid,
    );

    try {
      await _firestoreService.addTransaction(newTransaction);
      Appconstant.showSnackBar(
        context,
        message: "Transaction saved successfully!",
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      Appconstant.showSnackBar(
        context,
        message: "Failed to save transaction: $e",
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountStyle = TextStyle(
      fontSize: 48.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Add New Transaction",
          style: TextStyle(color: const Color(0xFF1B3253), fontSize: 22.sp),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3253)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              SizedBox(height: 30.h),

              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text("₹", style: amountStyle),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: amountStyle,
                      decoration: InputDecoration(
                        hintText: "0.00",
                        hintStyle: amountStyle.copyWith(
                          color: Colors.grey.shade300,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: 30.h),

              _buildCategoryDropdown(),
              SizedBox(height: 20.h),

              _buildDatePicker(),
              SizedBox(height: 20.h),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "e.g., Dinner with friends",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 40.h),

              Center(
                child: CommonAuthButton(
                  buttonText: "SAVE TRANSACTION",
                  onPressed: _handleSaveTransaction,
                  backgroundColor: const Color(0xFF1B3253),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    void onTypeChanged(String type) {
      setState(() {
        _transactionType = type;
        _selectedCategory = null;
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged('expense'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _transactionType == 'expense'
                      ? const Color(0xFFEB5757)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Center(
                  child: Text(
                    "Expense",
                    style: TextStyle(
                      color: _transactionType == 'expense'
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged('income'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _transactionType == 'income'
                      ? const Color(0xFF6FCF97)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Center(
                  child: Text(
                    "Income",
                    style: TextStyle(
                      color: _transactionType == 'income'
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No categories found.');
        }

        final categories = snapshot.data!;
        final filteredCategories = categories
            .where((cat) => cat.type == _transactionType)
            .toList();

        return DropdownButtonFormField<CategoryModel>(
          value: _selectedCategory,
          hint: const Text('Select Category'),
          isExpanded: true,
          onChanged: (CategoryModel? newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
          items: filteredCategories.map<DropdownMenuItem<CategoryModel>>((
            CategoryModel category,
          ) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Text(category.name),
            );
          }).toList(),
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null ? 'Please select a category' : null,
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
