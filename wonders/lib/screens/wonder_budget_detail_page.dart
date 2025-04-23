import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/user_wonder_model.dart';
import '../models/wonder_budget_model.dart';
import '../models/budget_transaction_model.dart';
import '../services/budget_service.dart';

class WonderBudgetDetailPage extends StatefulWidget {
  final UserWonderModel wonder;
  final WonderBudgetModel budget;
  final int initialTab;

  const WonderBudgetDetailPage({
    Key? key,
    required this.wonder,
    required this.budget,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  _WonderBudgetDetailPageState createState() => _WonderBudgetDetailPageState();
}

class _WonderBudgetDetailPageState extends State<WonderBudgetDetailPage>
    with SingleTickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  late TabController _tabController;
  late WonderBudgetModel _currentBudget;
  TransactionType _transactionType = TransactionType.saving;
  TransactionCategory _category = TransactionCategory.other;
  DateTime _transactionDate = DateTime.now();
  bool _isCreatingBudget = false;
  bool _isAddingTransaction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _currentBudget = widget.budget;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingBudget = true;
    });

    try {
      final double savingsGoal = double.tryParse(_amountController.text) ?? 0;

      if (_currentBudget.id.isEmpty) {
        // Create new budget
        final newBudget = WonderBudgetModel(
          id: '',
          wonderId: widget.wonder.id,
          userId: '',
          savingsGoal: savingsGoal,
          lastUpdated: DateTime.now(),
        );

        final budgetId = await _budgetService.saveBudget(newBudget);
        _currentBudget =
            await _budgetService.getBudgetForWonder(widget.wonder.id) ??
            _currentBudget;
      } else {
        // Update existing budget
        _currentBudget.savingsGoal = savingsGoal;
        await _budgetService.saveBudget(_currentBudget);
      }

      _amountController.clear();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Budget goal updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBudget = false;
        });
      }
    }
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAddingTransaction = true;
    });

    try {
      // Ensure we have a budget first
      if (_currentBudget.id.isEmpty) {
        // Create default budget if none exists
        final newBudget = WonderBudgetModel(
          id: '',
          wonderId: widget.wonder.id,
          userId: '',
          lastUpdated: DateTime.now(),
        );

        final budgetId = await _budgetService.saveBudget(newBudget);
        _currentBudget =
            await _budgetService.getBudgetForWonder(widget.wonder.id) ??
            _currentBudget;
      }

      final double amount = double.tryParse(_amountController.text) ?? 0;

      // Create transaction
      final transaction = BudgetTransactionModel(
        id: '',
        budgetId: _currentBudget.id,
        wonderId: widget.wonder.id,
        userId: '',
        type: _transactionType,
        amount: amount,
        description: _descriptionController.text,
        date: _transactionDate,
        category: _category,
      );

      await _budgetService.addTransaction(transaction);

      _amountController.clear();
      _descriptionController.clear();
      _transactionDate = DateTime.now();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingTransaction = false;
        });
      }
    }
  }

  void _showBudgetDialog() {
    _amountController.text =
        _currentBudget.savingsGoal > 0
            ? _currentBudget.savingsGoal.toString()
            : '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Set Savings Goal'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Goal Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
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
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: _isCreatingBudget ? null : _saveBudget,
                child:
                    _isCreatingBudget
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text('SAVE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  void _showTransactionDialog() {
    _amountController.clear();
    _descriptionController.clear();
    _transactionDate = DateTime.now();
    _transactionType =
        _tabController.index == 0
            ? TransactionType.saving
            : TransactionType.expense;
    _category = TransactionCategory.other;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              _transactionType == TransactionType.saving
                  ? 'Add Saving'
                  : 'Add Expense',
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter a valid positive amount';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    if (_transactionType == TransactionType.expense) ...[
                      DropdownButtonFormField<TransactionCategory>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            TransactionCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category
                                      .toString()
                                      .split('.')
                                      .last
                                      .capitalize(),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _category = value;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 16),
                    ],
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _transactionDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(Duration(days: 1)),
                        );

                        if (picked != null) {
                          setState(() {
                            _transactionDate = picked;
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: _dateFormat.format(_transactionDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: _isAddingTransaction ? null : _addTransaction,
                child:
                    _isAddingTransaction
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text('SAVE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTransaction(BudgetTransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Transaction'),
            content: Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('DELETE', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _budgetService.deleteTransaction(transaction);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wonder.name),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.cyanAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'SAVINGS', icon: Icon(Icons.savings)),
            Tab(
              text: widget.wonder.isCompleted ? 'EXPENSES' : 'PLANNED EXPENSES',
              icon: Icon(Icons.account_balance_wallet),
            ),
            Tab(text: 'SUMMARY', icon: Icon(Icons.pie_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSavingsTab(), _buildExpensesTab(), _buildSummaryTab()],
      ),
      floatingActionButton:
          _tabController.index != 2
              ? FloatingActionButton(
                onPressed:
                    _tabController.index == 0 && _currentBudget.id.isEmpty
                        ? _showBudgetDialog
                        : _showTransactionDialog,
                child: Icon(
                  _tabController.index == 0 && _currentBudget.id.isEmpty
                      ? Icons.add_chart
                      : Icons.add,
                ),
                backgroundColor: Colors.blue,
              )
              : null,
    );
  }

  Widget _buildSavingsTab() {
    return Column(
      children: [
        // Budget summary card
        _buildBudgetSummaryCard(),

        // Transactions list
        Expanded(
          child: StreamBuilder<List<BudgetTransactionModel>>(
            stream: _budgetService.getTransactionsForWonder(widget.wonder.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final transactions =
                  snapshot.data
                      ?.where((t) => t.type == TransactionType.saving)
                      .toList() ??
                  [];

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings, size: 60, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No savings recorded yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first saving with the + button',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _buildTransactionCard(transaction);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        // Budget summary card
        _buildBudgetSummaryCard(),

        // Transactions list
        Expanded(
          child: StreamBuilder<List<BudgetTransactionModel>>(
            stream: _budgetService.getTransactionsForWonder(widget.wonder.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final transactions =
                  snapshot.data
                      ?.where((t) => t.type == TransactionType.expense)
                      .toList() ??
                  [];

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.wonder.isCompleted
                            ? 'No expenses recorded yet'
                            : 'No planned expenses yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first expense with the + button',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _buildTransactionCard(transaction);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return StreamBuilder<List<BudgetTransactionModel>>(
      stream: _budgetService.getTransactionsForWonder(widget.wonder.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty && _currentBudget.id.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 60, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No budget data yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a budget and add transactions\nto see your summary',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showBudgetDialog,
                  icon: Icon(Icons.add_chart),
                  label: Text('Create Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // Group expenses by category for the pie chart
        Map<TransactionCategory, double> expensesByCategory = {};
        for (var transaction in transactions) {
          if (transaction.type == TransactionType.expense) {
            final category = transaction.category ?? TransactionCategory.other;
            expensesByCategory[category] =
                (expensesByCategory[category] ?? 0) + transaction.amount;
          }
        }

        // Group transactions by month for the line chart
        Map<DateTime, double> savingsByMonth = {};
        Map<DateTime, double> expensesByMonth = {};

        for (var transaction in transactions) {
          final monthKey = DateTime(
            transaction.date.year,
            transaction.date.month,
            1,
          );

          if (transaction.type == TransactionType.saving) {
            savingsByMonth[monthKey] =
                (savingsByMonth[monthKey] ?? 0) + transaction.amount;
          } else {
            expensesByMonth[monthKey] =
                (expensesByMonth[monthKey] ?? 0) + transaction.amount;
          }
        }

        // Sort keys for line chart
        final allMonths =
            {...savingsByMonth.keys, ...expensesByMonth.keys}.toList()
              ..sort((a, b) => a.compareTo(b));

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget Overview Card
              Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      Divider(),
                      _buildBudgetSummaryRow(
                        'Savings Goal:',
                        _currentBudget.savingsGoal > 0
                            ? _currencyFormat.format(_currentBudget.savingsGoal)
                            : 'Not set',
                        Colors.blue[800]!,
                      ),
                      SizedBox(height: 8),
                      _buildBudgetSummaryRow(
                        'Total Saved:',
                        _currencyFormat.format(_currentBudget.totalSaved),
                        Colors.green[700]!,
                      ),
                      if (_currentBudget.savingsGoal > 0) ...[
                        SizedBox(height: 8),
                        LinearPercentIndicator(
                          lineHeight: 12.0,
                          percent: (_currentBudget.totalSaved /
                                  _currentBudget.savingsGoal)
                              .clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          progressColor: Colors.green,
                          barRadius: Radius.circular(6),
                          padding: EdgeInsets.zero,
                          center: Text(
                            '${((_currentBudget.totalSaved / _currentBudget.savingsGoal) * 100).round()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  _currentBudget.totalSaved /
                                              _currentBudget.savingsGoal >
                                          0.5
                                      ? Colors.white
                                      : Colors.green[800],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      _buildBudgetSummaryRow(
                        widget.wonder.isCompleted
                            ? 'Total Spent:'
                            : 'Planned Expenses:',
                        widget.wonder.isCompleted
                            ? _currencyFormat.format(
                              _currentBudget.actualExpense,
                            )
                            : _currencyFormat.format(
                              _currentBudget.plannedExpense,
                            ),
                        widget.wonder.isCompleted
                            ? Colors.red[700]!
                            : Colors.orange[700]!,
                      ),
                      SizedBox(height: 8),
                      _buildBudgetSummaryRow(
                        'Difference:',
                        _currencyFormat.format(
                          _currentBudget.totalSaved -
                              (widget.wonder.isCompleted
                                  ? _currentBudget.actualExpense
                                  : _currentBudget.plannedExpense),
                        ),
                        _currentBudget.totalSaved >=
                                (widget.wonder.isCompleted
                                    ? _currentBudget.actualExpense
                                    : _currentBudget.plannedExpense)
                            ? Colors.green[700]!
                            : Colors.red[700]!,
                      ),
                    ],
                  ),
                ),
              ),

              // Expense by Category
              if (expensesByCategory.isNotEmpty) ...[
                Text(
                  'Expenses by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: PieChart(
                              PieChartData(
                                sections:
                                    expensesByCategory.entries.map((entry) {
                                      final color = _getCategoryColor(
                                        entry.key,
                                      );
                                      return PieChartSectionData(
                                        value: entry.value,
                                        title: '',
                                        radius: 80,
                                        color: color,
                                      );
                                    }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  expensesByCategory.entries.map((entry) {
                                    final color = _getCategoryColor(entry.key);
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            color: color,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              entry.key
                                                  .toString()
                                                  .split('.')
                                                  .last
                                                  .capitalize(),
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Monthly Trend
              if (allMonths.length > 1) ...[
                Text(
                  'Monthly Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Container(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(),
                          ),
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value < 0 || value >= allMonths.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = allMonths[value.toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('MMM yy').format(date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            // Savings line
                            LineChartBarData(
                              spots: List.generate(allMonths.length, (index) {
                                final month = allMonths[index];
                                return FlSpot(
                                  index.toDouble(),
                                  savingsByMonth[month] ?? 0,
                                );
                              }),
                              color: Colors.green,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withOpacity(0.1),
                              ),
                            ),
                            // Expenses line
                            LineChartBarData(
                              spots: List.generate(allMonths.length, (index) {
                                final month = allMonths[index];
                                return FlSpot(
                                  index.toDouble(),
                                  expensesByMonth[month] ?? 0,
                                );
                              }),
                              color: Colors.red,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.red.withOpacity(0.1),
                              ),
                            ),
                          ],
                          minX: 0,
                          maxX: allMonths.length - 1.toDouble(),
                          minY: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Savings', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      SizedBox(width: 16),
                      Row(
                        children: [
                          Container(width: 12, height: 12, color: Colors.red),
                          SizedBox(width: 4),
                          Text('Expenses', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetSummaryCard() {
    return Card(
      elevation: 3,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child:
            _currentBudget.id.isEmpty
                ? Center(
                  child: Column(
                    children: [
                      Text(
                        'No budget set',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _showBudgetDialog,
                        child: Text('Set Budget Goal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tabController.index == 0
                                  ? 'Savings Goal'
                                  : 'Planned Expense',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              _tabController.index == 0
                                  ? _currencyFormat.format(
                                    _currentBudget.savingsGoal,
                                  )
                                  : _currencyFormat.format(
                                    _currentBudget.plannedExpense,
                                  ),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color:
                                    _tabController.index == 0
                                        ? Colors.blue[800]
                                        : Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                        if (_tabController.index == 0)
                          OutlinedButton(
                            onPressed: _showBudgetDialog,
                            child: Text('Edit Goal'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                    if (_tabController.index == 0 &&
                        _currentBudget.savingsGoal > 0) ...[
                      SizedBox(height: 16),
                      LinearPercentIndicator(
                        lineHeight: 16.0,
                        percent: (_currentBudget.totalSaved /
                                _currentBudget.savingsGoal)
                            .clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        progressColor: Colors.blue,
                        barRadius: Radius.circular(8),
                        padding: EdgeInsets.zero,
                        center: Text(
                          '${((_currentBudget.totalSaved / _currentBudget.savingsGoal) * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                _currentBudget.totalSaved /
                                            _currentBudget.savingsGoal >
                                        0.5
                                    ? Colors.white
                                    : Colors.blue[800],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currencyFormat.format(_currentBudget.totalSaved)} saved',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${_currencyFormat.format(_currentBudget.savingsGoal - _currentBudget.totalSaved)} to go',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
      ),
    );
  }

  Widget _buildTransactionCard(BudgetTransactionModel transaction) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red[700] : Colors.green[700];
    final icon =
        isExpense ? _getCategoryIcon(transaction.category!) : Icons.savings;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color!.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(transaction.description),
        subtitle: Text(_dateFormat.format(transaction.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currencyFormat.format(transaction.amount),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteTransaction(transaction),
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.transportation:
        return Colors.blue[400]!;
      case TransactionCategory.accommodation:
        return Colors.purple[400]!;
      case TransactionCategory.food:
        return Colors.orange[400]!;
      case TransactionCategory.attractions:
        return Colors.green[400]!;
      case TransactionCategory.shopping:
        return Colors.pink[400]!;
      case TransactionCategory.other:
        return Colors.grey[400]!;
    }
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.transportation:
        return Icons.directions_car;
      case TransactionCategory.accommodation:
        return Icons.hotel;
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.attractions:
        return Icons.attractions;
      case TransactionCategory.shopping:
        return Icons.shopping_bag;
      case TransactionCategory.other:
        return Icons.category;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
