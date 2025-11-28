import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/transaction_model.dart';
import '../data/dashboard_stats.dart';
import '../services/api_service.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService api;

  const HomeScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Метод для навігації на екран додавання.
  // Використовує async/await, щоб дочекатися результату.
  // Якщо result == true (транзакція збережена), ми оновлюємо екран через setState.
  void _navigateToAddScreen(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          type: type,
          api: widget.api,
        ),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Успішно збережено!"), backgroundColor: Colors.green),
      );
      setState(() {}); // Оновлення UI для відображення нових даних
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer дозволяє отримати доступ до стану ApiService (наприклад, поточного користувача)
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        final userEmail = apiService.currentUser?.email ?? "Гість";
        // Витягуємо ім'я з email до символу @ для привітання
        final userName = userEmail.contains('@') ? userEmail.split('@')[0] : userEmail;

        return Scaffold(
          backgroundColor: Color(0xFFF6F7F9),
          body: SafeArea(
            // RefreshIndicator дозволяє оновити дані свайпом вниз (pull-to-refresh)
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {}); // Перебудовує віджет, що запускає нові запити FutureBuilder
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildHeader(userName),
                  SizedBox(height: 20),

                  // FutureBuilder для отримання статистики (баланс, доходи, витрати).
                  // Дозволяє будувати інтерфейс в залежності від стану запиту (завантаження/дані/помилка).
                  FutureBuilder<DashboardStats?>(
                    future: apiService.getDashboardStats(),
                    builder: (context, snapshot) {
                      // Поки дані вантажаться, показуємо "заглушку" або спінер
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildBalanceCard(0, 0, 0, isLoading: true);
                      }
                      final stats = snapshot.data;
                      return _buildBalanceCard(
                        stats?.currentBalance ?? 0,
                        stats?.lastMonthIncome ?? 0,
                        stats?.lastMonthExpenses ?? 0,
                      );
                    },
                  ),

                  SizedBox(height: 20),
                  _buildActionButtons(),
                  SizedBox(height: 30),
                  _buildRecentTransactionsHeader(),
                  SizedBox(height: 10),

                  // Другий FutureBuilder для отримання списку транзакцій
                  FutureBuilder<List<TransactionModel>>(
                    future: apiService.getTransactions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final data = snapshot.data ?? [];
                      return _buildRecentTransactionList(data);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Добрий день,", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(icon: Icon(Icons.notifications_none, size: 28), onPressed: () {}),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _buildActionButton("Додати дохід", Icon(Icons.add, color: Colors.green), Colors.green[50]!, () => _navigateToAddScreen('income'))),
        SizedBox(width: 16),
        Expanded(child: _buildActionButton("Додати витрату", Icon(Icons.remove, color: Colors.red), Colors.red[50]!, () => _navigateToAddScreen('expense'))),
      ],
    );
  }

  Widget _buildActionButton(String title, Icon icon, Color backgroundColor, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(children: [icon, SizedBox(height: 8), Text(title, style: TextStyle(fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Останні транзакції", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBalanceCard(double total, double income, double expense, {bool isLoading = false}) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Загальний баланс", style: TextStyle(fontSize: 14, color: Colors.white70)),
          SizedBox(height: 10),
          isLoading
              ? SizedBox(height: 38, width: 38, child: CircularProgressIndicator(color: Colors.white))
              : Text(
            "₴${total.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseBlock("Дохід (міс)", isLoading ? "..." : "₴${income.toStringAsFixed(0)}"),
              _buildIncomeExpenseBlock("Витрати (міс)", isLoading ? "..." : "₴${expense.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseBlock(String title, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.white70)),
        SizedBox(height: 4),
        Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildRecentTransactionList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text("Транзакцій поки немає.", style: TextStyle(color: Colors.grey)),
      );
    }

    // Відображаємо тільки останні 5 транзакцій на головному екрані
    final displayList = transactions.take(5).toList();

    return Column(
      children: displayList.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: TransactionTile(
            title: t.description,
            subtitle: "${t.date.day}.${t.date.month}.${t.date.year}",
            amount: "${t.type == 'income' ? '+' : ''}₴${t.amount.abs().toStringAsFixed(0)}",
            amountColor: t.type == 'income' ? Colors.green : Colors.red,
            iconEmoji: t.categoryIcon,
            iconBgColor: t.categoryColor,
            onTap: () {
              // Навігація до екрану деталей транзакції
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailsScreen(
                    transaction: t,
                    api: widget.api,
                  ),
                ),
              ).then((_) => setState(() {})); // Оновлення списку після повернення
            },
          ),
        );
      }).toList(),
    );
  }
}