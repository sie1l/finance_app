import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/transaction_model.dart';
import '../services/api_service.dart';
import 'add_transaction_screen.dart';

// Екран детального перегляду транзакції.
// Дозволяє переглянути повну інформацію, а також видалити або редагувати запис.
class TransactionDetailsScreen extends StatefulWidget {
  final TransactionModel transaction;
  final ApiService api;

  const TransactionDetailsScreen({
    Key? key,
    required this.transaction,
    required this.api,
  }) : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  late TransactionModel _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
  }

  // Метод видалення транзакції.
  // Спочатку показує діалог підтвердження (AlertDialog), щоб уникнути випадкового видалення.
  void _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Видалити транзакцію?"),
        content: Text("Цю дію неможливо відмінити."),
        actions: [
          TextButton(child: Text("Скасувати"), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(
              child: Text("Видалити", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(ctx, true) // Повертає true
          ),
        ],
      ),
    );

    // Якщо користувач підтвердив — видаляємо через API і закриваємо екран.
    if (confirm == true) {
      await widget.api.deleteTransaction(_transaction.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  // Метод редагування.
  // Ми перевикористовуємо AddTransactionScreen, передаючи туди поточну транзакцію.
  void _editTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          api: widget.api,
          transaction: _transaction, // Передаємо об'єкт для редагування
        ),
      ),
    );

    // Якщо редагування пройшло успішно (result == true), закриваємо цей екран,
    // щоб оновити дані на головному списку.
    if (result == true) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Визначаємо стиль залежно від типу транзакції (Дохід - зелений, Витрата - червоний)
    final isIncome = _transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editTransaction,
            tooltip: "Редагувати",
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteTransaction,
            tooltip: "Видалити",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Велике коло з іконкою категорії
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _transaction.categoryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                _transaction.categoryIcon,
                style: TextStyle(fontSize: 48),
              ),
            ),
            SizedBox(height: 24),

            // Сума з відповідним кольором
            Text(
              "${isIncome ? '+' : ''} ₴${_transaction.amount.abs().toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color
              ),
            ),
            SizedBox(height: 8),
            Text(
              _transaction.description,
              style: TextStyle(fontSize: 18, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Блок детальної інформації
            _buildDetailRow(Icons.category, "Категорія", _transaction.categoryName),
            Divider(),
            _buildDetailRow(Icons.calendar_today, "Дата", dateFormat.format(_transaction.date)),
            Divider(),
            _buildDetailRow(
                isIncome ? Icons.account_balance_wallet : Icons.shopping_bag,
                "Тип",
                isIncome ? "Дохід" : "Витрата"
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}