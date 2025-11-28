import 'category_model.dart';

class CategoryStat {
  final CategoryModel category;
  final double totalAmount;
  final double percentage;

  CategoryStat({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      // Парсинг вкладеного JSON-об'єкта.
      // API повертає структуру категорії всередині статистики, тому ми викликаємо метод fromJson моделі CategoryModel.
      category: CategoryModel.fromJson(json['category']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class DailyStat {
  final DateTime date;
  final double income;
  final double expense;

  DailyStat({
    required this.date,
    required this.income,
    required this.expense,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    return DailyStat(
      // Перетворення рядка (ISO 8601) з API у об'єкт DateTime.
      date: DateTime.parse(json['date']),
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );
  }
}