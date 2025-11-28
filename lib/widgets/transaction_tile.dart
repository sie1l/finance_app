import 'package:flutter/material.dart';

// Кастомний віджет для відображення одного рядка транзакції у списку.
// Використання окремого віджета дозволяє дотримуватися принципу DRY (Don't Repeat Yourself).
class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final String iconEmoji;
  final Color iconBgColor;
  final VoidCallback? onTap;

  const TransactionTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.iconEmoji,
    required this.iconBgColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // InkWell додає ефект "хвилі" (ripple effect) при натисканні, що важливо для UX.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // Круглий фон для іконки категорії
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Text(
                iconEmoji,
                style: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(width: 12),
            // Expanded змушує колонку з текстом займати весь доступний простір між іконкою та сумою.
            // Без цього довгий текст міг би "зламати" верстку.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            // Сума відображається справа
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}