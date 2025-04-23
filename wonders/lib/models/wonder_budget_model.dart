import 'package:cloud_firestore/cloud_firestore.dart';

class WonderBudgetModel {
  final String id;
  final String wonderId;
  final String userId;
  double savingsGoal;
  double totalSaved;
  double plannedExpense;
  double actualExpense;
  DateTime lastUpdated;

  WonderBudgetModel({
    required this.id,
    required this.wonderId,
    required this.userId,
    this.savingsGoal = 0.0,
    this.totalSaved = 0.0,
    this.plannedExpense = 0.0,
    this.actualExpense = 0.0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'wonderId': wonderId,
      'userId': userId,
      'savingsGoal': savingsGoal,
      'totalSaved': totalSaved,
      'plannedExpense': plannedExpense,
      'actualExpense': actualExpense,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  factory WonderBudgetModel.fromJson(String id, Map<String, dynamic> json) {
    return WonderBudgetModel(
      id: id,
      wonderId: json['wonderId'] ?? '',
      userId: json['userId'] ?? '',
      savingsGoal: (json['savingsGoal'] ?? 0.0).toDouble(),
      totalSaved: (json['totalSaved'] ?? 0.0).toDouble(),
      plannedExpense: (json['plannedExpense'] ?? 0.0).toDouble(),
      actualExpense: (json['actualExpense'] ?? 0.0).toDouble(),
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
              : DateTime.now(),
    );
  }
}
