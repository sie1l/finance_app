import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final String colorHex;

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
  });

  // Перетворює текстовий HEX-код (з API) у колір Flutter.
  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey; // Повертає сірий, якщо прийшов некоректний код
    }
  }

  // Створює об'єкт категорії з JSON (при отриманні даних з сервера).
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'] ?? '📦', // Значення за замовчуванням
      colorHex: json['color'] ?? '#CCCCCC',
    );
  }

  // Перетворює об'єкт у JSON (для відправки на сервер).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': colorHex,
    };
  }
}