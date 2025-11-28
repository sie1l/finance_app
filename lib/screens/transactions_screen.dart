import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/transaction_model.dart';
import '../services/api_service.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_details_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Зберігає стан кнопок фільтру: [Всі, Доходи, Витрати].
  // Тільки один елемент може бути true.
  List<bool> _isSelected = [true, false, false];

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF6F7F9),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Color(0xFFF6F7F9),
            title: Text(
              "Транзакції",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _buildFilters(), // Віджет перемикачів
                ),
                Expanded(
                  child: FutureBuilder<List<TransactionModel>>(
                    future: apiService.getTransactions(), // Отримуємо ВСІ транзакції
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("Транзакцій немає"));
                      }

                      final allData = snapshot.data!;
                      List<TransactionModel> displayData = [];

                      // Логіка локальної фільтрації:
                      // Фільтруємо отриманий список залежно від того, яка кнопка активна.
                      if (_isSelected[0]) {
                        displayData = allData;
                      } else if (_isSelected[1]) {
                        displayData = allData.where((t) => t.type == 'income').toList();
                      } else {
                        displayData = allData.where((t) => t.type == 'expense').toList();
                      }

                      if (displayData.isEmpty) {
                        return Center(child: Text("У цій категорії пусто"));
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: displayData.length,
                        itemBuilder: (context, index) {
                          final t = displayData[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: TransactionTile(
                              title: t.description,
                              subtitle: "${t.date.day}.${t.date.month} • ${t.date.hour}:${t.date.minute.toString().padLeft(2, '0')}",
                              amount: "${t.type == 'income' ? '+' : ''}₴${t.amount.abs().toStringAsFixed(0)}",
                              amountColor: t.type == 'income' ? Colors.green : Colors.red,

                              iconEmoji: t.categoryIcon,
                              iconBgColor: t.categoryColor,

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionDetailsScreen(
                                      transaction: t,
                                      api: apiService,
                                    ),
                                  ),
                                ).then((_) => setState(() {})); // Важливо: оновлюємо список після повернення (на випадок видалення)
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Center(
      child: ToggleButtons(
        children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Всі")),
          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Доходи")),
          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Витрати")),
        ],
        isSelected: _isSelected,
        onPressed: (int index) {
          setState(() {
            // Оновлюємо масив _isSelected так, щоб тільки натиснута кнопка стала true
            for (int i = 0; i < _isSelected.length; i++) {
              _isSelected[i] = (i == index);
            }
          });
        },
        borderRadius: BorderRadius.circular(10.0),
        selectedColor: Colors.white,
        fillColor: Color(0xFF1E2A3A),
        color: Colors.black,
        borderColor: Colors.grey[300],
        selectedBorderColor: Color(0xFF1E2A3A),
        constraints: BoxConstraints(minHeight: 40.0),
      ),
    );
  }
}