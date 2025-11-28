import 'package:flutter/material.dart';

// Екран відновлення пароля.
// Дозволяє користувачеві ввести пошту, щоб отримати посилання для скидання пароля.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Прибираємо тінь для "плоского" дизайну
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Центруємо вміст по вертикалі
            crossAxisAlignment: CrossAxisAlignment.stretch, // Розтягуємо елементи на всю ширину екрану
            children: [
              // Декоративний елемент з іконкою замка
              Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.black,
                    size: 40,
                  ),
                  width: 64,
                  height: 64,
                ),
              ),

              SizedBox(height: 24),

              Text(
                "Відновлення пароля",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Введіть вашу пошту для відновлення",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              SizedBox(height: 32),

              Text(
                "Електронна пошта",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              // Поле введення Email
              TextField(
                keyboardType: TextInputType.emailAddress, // Клавіатура з @ для зручності
                decoration: InputDecoration(
                  hintText: "your@email.com",
                  fillColor: Color(0xFFF6F7F9),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Інформаційне повідомлення для користувача
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Ми надішлемо вам посилання для скидання пароля на вказану електронну адресу.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),

              SizedBox(height: 20),

              // Кнопка відправки запиту
              ElevatedButton(
                onPressed: () {
                  // Тут має викликатися метод API для відновлення пароля
                },
                child: Text("Відправити посилання", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E2A3A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Блок навігації назад на екран входу
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Згадали пароль? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Повернення на попередній екран (LoginScreen)
                    },
                    child: Text(
                      "Увійти",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}