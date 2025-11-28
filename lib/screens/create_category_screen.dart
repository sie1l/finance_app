import 'package:flutter/material.dart';
import '../data/category_model.dart';
import '../services/api_service.dart';

class CreateCategoryScreen extends StatefulWidget {
  final String type; // 'income' або 'expense'
  final ApiService api;

  const CreateCategoryScreen({Key? key, required this.type, required this.api}) : super(key: key);

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _nameController = TextEditingController();

  // Змінні стану для зберігання вибору користувача
  String _selectedEmoji = "🍔";
  Color _selectedColor = Colors.blue;

  final List<String> _emojis = [
    "🍔", "🛍️", "🏠", "🚌", "✈️", "🎓", "💪", "🐶",
    "💼", "📱", "🔧", "🏥", "☕", "🎬", "🎵", "🎮",
    "💰", "🎁", "🛒", "💊", "💅", "👶", "📚", "💸"
  ];

  final List<Color> _colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.brown,
    Colors.indigo, Colors.amber, Colors.cyan, Colors.blueGrey,
  ];

  void _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Конвертація об'єкта Color у HEX-рядок (наприклад, "#FF0000").
    // API очікує колір у форматі тексту, тому ми беремо значення кольору і переводимо в 16-річну систему.
    String colorHex = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

    final newCategory = CategoryModel(
      name: name,
      // Тут ми не передаємо ID, бо його створить сервер (база даних)
      icon: _selectedEmoji,
      colorHex: colorHex,
    );

    // Відправка POST-запиту на сервер для створення категорії
    await widget.api.addCategory(newCategory);

    if (mounted) Navigator.pop(context, true); // Повертаємо true, щоб оновити попередній екран
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Нова категорія", style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Блок попереднього перегляду (Прев'ю)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _selectedEmoji,
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _nameController.text.isEmpty ? "Назва категорії" : _nameController.text,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            TextField(
              controller: _nameController,
              // Викликаємо setState при кожному введенні символу, щоб оновлювати прев'ю в реальному часі
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                labelText: "Назва",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 20),

            Text("Колір", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            // Wrap дозволяє автоматично переносити елементи на новий рядок, якщо вони не влазять в ширину
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: color,
                    // Відображаємо галочку тільки на обраному кольорі
                    child: _selectedColor == color
                        ? Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            Text("Іконка", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _emojis.map((emoji) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedEmoji == emoji ? Colors.grey[200] : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedEmoji == emoji ? Colors.black : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(emoji, style: TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 40),

            ElevatedButton(
              onPressed: _saveCategory,
              child: Text("Створити категорію", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E2A3A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}