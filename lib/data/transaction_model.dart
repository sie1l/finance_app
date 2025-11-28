import 'package:flutter/material.dart';
import 'category_model.dart';

class TransactionModel {
  final int? id;
  final String type;
  final double amount;
  final String description;
  final DateTime date;

  final int? categoryId;
  final String categoryName;
  final String categoryIcon;
  final Color categoryColor;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final catData = json['category'];

    // Значення за замовчуванням ("заглушки"), якщо категорії немає.
    String catName = 'Інше';
    String catIcon = '❓';
    Color catColor = Colors.grey;
    int? catId;

    // Парсинг вкладеного об'єкта категорії.
    if (catData != null) {
      final category = CategoryModel.fromJson(catData);
      catName = category.name;
      catIcon = category.icon;
      catColor = category.color;
      catId = category.id;
    }

    return TransactionModel(
      id: json['id'],
      type: json['type'],
      // Безпечне перетворення суми (обробка int/double/String).
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      description: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      categoryId: catId,
      categoryName: catName,
      categoryIcon: catIcon,
      categoryColor: catColor,
    );
  }
}