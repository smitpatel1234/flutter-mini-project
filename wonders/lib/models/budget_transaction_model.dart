enum TransactionType { saving, expense }

enum TransactionCategory {
  transportation,
  accommodation,
  food,
  attractions,
  shopping,
  other,
}

class BudgetTransactionModel {
  final String id;
  final String budgetId;
  final String wonderId;
  final String userId;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final TransactionCategory? category;

  BudgetTransactionModel({
    required this.id,
    required this.budgetId,
    required this.wonderId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'budgetId': budgetId,
      'wonderId': wonderId,
      'userId': userId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'category': category?.toString().split('.').last,
    };
  }

  factory BudgetTransactionModel.fromJson(
    String id,
    Map<String, dynamic> json,
  ) {
    return BudgetTransactionModel(
      id: id,
      budgetId: json['budgetId'] ?? '',
      wonderId: json['wonderId'] ?? '',
      userId: json['userId'] ?? '',
      type:
          json['type'] == 'saving'
              ? TransactionType.saving
              : TransactionType.expense,
      amount: (json['amount'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      date:
          json['date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['date'])
              : DateTime.now(),
      category:
          json['category'] != null
              ? TransactionCategory.values.firstWhere(
                (e) => e.toString().split('.').last == json['category'],
                orElse: () => TransactionCategory.other,
              )
              : null,
    );
  }
}
