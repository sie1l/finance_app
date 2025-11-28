import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/category_model.dart';
import '../data/transaction_model.dart';
import '../services/api_service.dart';
import 'create_category_screen.dart';

// Екран для створення нової транзакції або редагування існуючої.
// Використовує універсальний підхід: приймає або type (для нової), або transaction (для редагування).
class AddTransactionScreen extends StatefulWidget {
  final ApiService api;
  final TransactionModel? transaction; // Якщо != null -> режим редагування
  final String? type; // 'income' або 'expense' (якщо створюємо нову)

  const AddTransactionScreen({
    Key? key,
    required this.api,
    this.transaction,
    this.type,
  }) : assert(transaction != null || type != null, 'Потрібно передати transaction або type'),
        super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = true; // Стан завантаження категорій
  bool _isSaving = false; // Стан збереження транзакції
  DateTime _selectedDate = DateTime.now();

  // Геттери для зручності: перевірка режиму та типу транзакції
  bool get _isEditing => widget.transaction != null;
  String get _transactionType => _isEditing ? widget.transaction!.type : widget.type!;

  @override
  void initState() {
    super.initState();
    // Якщо редагуємо -> заповнюємо поля існуючими даними
    if (_isEditing) {
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _selectedDate = widget.transaction!.date;
    }
    _loadCategories(); // Завантажуємо категорії з API
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cats = await widget.api.getCategories(_transactionType);

    setState(() {
      _categories = cats;
      _isLoading = false;

      // Логіка вибору категорії за замовчуванням
      if (_isEditing) {
        try {
          // Шукаємо категорію, яка була обрана раніше
          _selectedCategory = _categories.firstWhere(
                  (c) => c.id == widget.transaction!.categoryId || c.name == widget.transaction!.categoryName
          );
        } catch (e) {
          if (_categories.isNotEmpty) _selectedCategory = _categories.first;
        }
      } else {
        // Якщо це нова транзакція, обираємо першу зі списку
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      }
    });
  }

  // Метод для вибору дати та часу
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale("uk", "UA"), // Локалізація календаря
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    setState(() {
      // Об'єднуємо обрану дату та час в один об'єкт DateTime
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // Збереження транзакції
  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Введіть суму та оберіть категорію")),
      );
      return;
    }

    // Парсинг суми (заміна коми на крапку для коректного перетворення)
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Некоректна сума")));
      return;
    }

    final name = _descriptionController.text.trim().isEmpty
        ? _selectedCategory!.name
        : _descriptionController.text.trim();

    setState(() => _isSaving = true);

    bool success;
    if (_isEditing) {
      // Оновлення існуючої транзакції
      success = await widget.api.updateTransaction(
        widget.transaction!.id!,
        type: _transactionType,
        amount: amount,
        name: name,
        categoryId: _selectedCategory!.id!,
        date: _selectedDate,
      );
    } else {
      // Створення нової транзакції
      success = await widget.api.addTransaction(
        _transactionType,
        amount,
        name,
        _selectedCategory!.id!,
        _selectedDate,
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) Navigator.pop(context, true); // Повертаємо true, щоб оновити список на головному екрані
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Помилка при збереженні"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Відкриття екрану створення нової категорії
  void _openCreateCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCategoryScreen(
          type: _transactionType,
          api: widget.api,
        ),
      ),
    );

    // Якщо категорія створена успішно, оновлюємо список
    if (result == true) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _transactionType == 'income'
        ? (_isEditing ? "Редагувати дохід" : "Додати дохід")
        : (_isEditing ? "Редагувати витрату" : "Додати витрату");

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Color(0xFFF6F7F9),
        elevation: 0,
        title: Text(title, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Поле введення суми
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Сума",
                  hintText: "0.00",
                  prefixText: "₴ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Вибір дати (кастомний віджет-кнопка)
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[700]),
                      SizedBox(width: 10),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(_selectedDate),
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      Spacer(),
                      Text("Змінити", style: TextStyle(color: Color(0xFF1E2A3A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Горизонтальний список категорій
              Text("Категорія", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1, // +1 для кнопки "Створити"
                  itemBuilder: (context, index) {
                    if (index == _categories.length) {
                      // Кнопка додавання нової категорії
                      return GestureDetector(
                        onTap: _openCreateCategory,
                        child: Container(
                          margin: EdgeInsets.only(right: 12),
                          width: 70,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(radius: 25, backgroundColor: Colors.grey[300], child: Icon(Icons.add, color: Colors.black)),
                              SizedBox(height: 5),
                              Text("Створити", style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    }
                    final cat = _categories[index];
                    final isSelected = _selectedCategory?.id == cat.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: EdgeInsets.only(right: 12),
                        width: 70,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Виділення обраної категорії рамкою
                                border: isSelected ? Border.all(color: Color(0xFF1E2A3A), width: 2) : null,
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: cat.color.withOpacity(0.2),
                                child: Text(cat.icon, style: TextStyle(fontSize: 24)),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(cat.name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              // Поле коментаря
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Коментар",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              Spacer(),
              // Кнопка збереження
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveTransaction,
                  child: _isSaving
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? "Зберегти зміни" : "Створити", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E2A3A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}