import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wonder_budget_model.dart';
import '../models/budget_transaction_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Create or update budget for a wonder
  Future<String> saveBudget(WonderBudgetModel budget) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    if (budget.id.isEmpty) {
      // Create new budget
      final docRef = _firestore.collection('wonder_budgets').doc();
      final budgetId = docRef.id;

      final newBudget = WonderBudgetModel(
        id: budgetId,
        wonderId: budget.wonderId,
        userId: _userId!,
        savingsGoal: budget.savingsGoal,
        totalSaved: budget.totalSaved,
        plannedExpense: budget.plannedExpense,
        actualExpense: budget.actualExpense,
        lastUpdated: DateTime.now(),
      );

      await docRef.set(newBudget.toJson());
      return budgetId;
    } else {
      // Update existing budget
      await _firestore.collection('wonder_budgets').doc(budget.id).update({
        'savingsGoal': budget.savingsGoal,
        'totalSaved': budget.totalSaved,
        'plannedExpense': budget.plannedExpense,
        'actualExpense': budget.actualExpense,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      return budget.id;
    }
  }

  // Get budget for a specific wonder
  Future<WonderBudgetModel?> getBudgetForWonder(String wonderId) async {
    if (_userId == null) return null;

    final querySnapshot =
        await _firestore
            .collection('wonder_budgets')
            .where('wonderId', isEqualTo: wonderId)
            .where('userId', isEqualTo: _userId)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) return null;

    return WonderBudgetModel.fromJson(
      querySnapshot.docs.first.id,
      querySnapshot.docs.first.data(),
    );
  }

  // Get all budgets for current user
  Stream<List<WonderBudgetModel>> getUserBudgets() {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('wonder_budgets')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WonderBudgetModel.fromJson(doc.id, doc.data()))
              .toList();
        });
  }

  // Add a transaction
  Future<String> addTransaction(BudgetTransactionModel transaction) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Create document reference
    final docRef = _firestore.collection('budget_transactions').doc();
    final transactionId = docRef.id;

    // Create transaction with new ID
    final newTransaction = BudgetTransactionModel(
      id: transactionId,
      budgetId: transaction.budgetId,
      wonderId: transaction.wonderId,
      userId: _userId!,
      type: transaction.type,
      amount: transaction.amount,
      description: transaction.description,
      date: transaction.date,
      category: transaction.category,
    );

    // Save to Firestore
    await docRef.set(newTransaction.toJson());

    // Update budget totals
    final budget = await getBudgetForWonder(transaction.wonderId);
    if (budget != null) {
      if (transaction.type == TransactionType.saving) {
        budget.totalSaved += transaction.amount;
      } else {
        budget.actualExpense += transaction.amount;
      }

      await saveBudget(budget);
    }

    return transactionId;
  }

  // Get all transactions for a wonder
  Stream<List<BudgetTransactionModel>> getTransactionsForWonder(
    String wonderId,
  ) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('budget_transactions')
        .where('wonderId', isEqualTo: wonderId)
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BudgetTransactionModel.fromJson(doc.id, doc.data()))
              .toList();
        });
  }

  // Delete a transaction
  Future<void> deleteTransaction(BudgetTransactionModel transaction) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Delete from Firestore
    await _firestore
        .collection('budget_transactions')
        .doc(transaction.id)
        .delete();

    // Update budget totals
    final budget = await getBudgetForWonder(transaction.wonderId);
    if (budget != null) {
      if (transaction.type == TransactionType.saving) {
        budget.totalSaved -= transaction.amount;
      } else {
        budget.actualExpense -= transaction.amount;
      }

      await saveBudget(budget);
    }
  }
}
