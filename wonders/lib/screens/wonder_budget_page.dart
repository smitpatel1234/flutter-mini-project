import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/user_wonder_model.dart';
import '../models/wonder_budget_model.dart';
import '../services/wonder_service.dart';
import '../services/budget_service.dart';
import 'wonder_budget_detail_page.dart';

class WonderBudgetPage extends StatefulWidget {
  const WonderBudgetPage({Key? key}) : super(key: key);

  @override
  _WonderBudgetPageState createState() => _WonderBudgetPageState();
}

class _WonderBudgetPageState extends State<WonderBudgetPage>
    with SingleTickerProviderStateMixin {
  final WonderService _wonderService = WonderService();
  final BudgetService _budgetService = BudgetService();
  late TabController _tabController;

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wonder Budget Tracker'),
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
            Tab(text: 'UNVISITED', icon: Icon(Icons.flight_takeoff)),
            Tab(text: 'VISITED', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWondersList(false), // Unvisited wonders
          _buildWondersList(true), // Visited wonders
        ],
      ),
    );
  }

  Widget _buildWondersList(bool isCompleted) {
    return StreamBuilder<List<UserWonderModel>>(
      stream: _wonderService.getUserWonders(),
      builder: (context, wonderSnapshot) {
        if (wonderSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (wonderSnapshot.hasError) {
          return Center(child: Text('Error: ${wonderSnapshot.error}'));
        }

        final wonders =
            wonderSnapshot.data
                ?.where((wonder) => wonder.isCompleted == isCompleted)
                .toList() ??
            [];

        if (wonders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.travel_explore : Icons.flight_takeoff,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  isCompleted
                      ? 'No visited wonders yet'
                      : 'No planned wonders yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isCompleted
                      ? 'Mark wonders as visited to track expenses'
                      : 'Start planning your adventures',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<WonderBudgetModel>>(
          stream: _budgetService.getUserBudgets(),
          builder: (context, budgetSnapshot) {
            if (budgetSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final budgets = budgetSnapshot.data ?? [];

            return ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: wonders.length,
              itemBuilder: (context, index) {
                final wonder = wonders[index];
                final budget = budgets.firstWhere(
                  (b) => b.wonderId == wonder.id,
                  orElse:
                      () => WonderBudgetModel(
                        id: '',
                        wonderId: wonder.id,
                        userId: '',
                        lastUpdated: DateTime.now(),
                      ),
                );

                return _buildBudgetCard(wonder, budget);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBudgetCard(UserWonderModel wonder, WonderBudgetModel budget) {
    double savingsProgress =
        budget.savingsGoal > 0 ? budget.totalSaved / budget.savingsGoal : 0.0;

    // Clamp progress to 1.0 max for visual display
    savingsProgress = savingsProgress.clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      WonderBudgetDetailPage(wonder: wonder, budget: budget),
            ),
          ).then((_) => setState(() {}));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                image:
                    wonder.imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(wonder.imageUrl!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        )
                        : null,
                color: wonder.imageUrl == null ? Colors.blue[100] : null,
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    wonder.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  if (wonder.location != null && wonder.location!.isNotEmpty)
                    Text(
                      wonder.location!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Budget content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Savings Goal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Savings Goal:',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                      Text(
                        budget.id.isEmpty
                            ? 'Not set'
                            : currencyFormat.format(budget.savingsGoal),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Savings Progress Bar
                  if (budget.savingsGoal > 0) ...[
                    LinearPercentIndicator(
                      lineHeight: 12.0,
                      percent: savingsProgress,
                      backgroundColor: Colors.blue[50],
                      progressColor: Colors.blue,
                      barRadius: Radius.circular(6),
                      padding: EdgeInsets.zero,
                      center: Text(
                        '${(savingsProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              savingsProgress > 0.5
                                  ? Colors.white
                                  : Colors.blue[800],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],

                  // Saved and Expenses Summary
                  Row(
                    children: [
                      // Savings
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saved',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              currencyFormat.format(budget.totalSaved),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Expenses
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wonder.isCompleted ? 'Spent' : 'Planned',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              wonder.isCompleted
                                  ? currencyFormat.format(budget.actualExpense)
                                  : currencyFormat.format(
                                    budget.plannedExpense,
                                  ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    wonder.isCompleted
                                        ? Colors.red[700]
                                        : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WonderBudgetDetailPage(
                                      wonder: wonder,
                                      budget: budget,
                                      initialTab: 0, // Savings tab
                                    ),
                              ),
                            );
                          },
                          icon: Icon(Icons.savings, size: 16),
                          label: Text('Savings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WonderBudgetDetailPage(
                                      wonder: wonder,
                                      budget: budget,
                                      initialTab: 1, // Expenses tab
                                    ),
                              ),
                            );
                          },
                          icon: Icon(Icons.account_balance_wallet, size: 16),
                          label: Text(wonder.isCompleted ? 'Expenses' : 'Plan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                wonder.isCompleted
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
