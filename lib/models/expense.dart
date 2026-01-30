import 'dart:convert';

ExpenseModel expenseModelFromJson(String str) =>
    ExpenseModel.fromJson(json.decode(str));

String expenseModelToJson(ExpenseModel data) => json.encode(data.toJson());

class ExpenseModel {
  final String id;
  final double amount;
  final DateTime date;
  final String categoryId;
  String? description;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.description,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json["id"],
    amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
    // Dates in JSON are typically strings, so parsed it into a DateTime object
    date: DateTime.parse(json["date"]),
    categoryId: json["categoryId"],
    description: json["description"],
  );

  // Method to convert the instance to a JSON map
  Map<String, dynamic> toJson() => {
    "id": id,
    "amount": amount,
    // Convert the DateTime object back to a standard ISO 8601 string for JSON
    "date": date.toIso8601String(),
    "categoryId": categoryId,
    "description": description,
  };

  ExpenseModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? description,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
    );
  }
}
