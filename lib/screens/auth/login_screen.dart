import 'package:flutter/material.dart';
import 'package:finance_app/services/api_service.dart';
import 'package:finance_app/screens/main_navigation_wrapper.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final ApiService api;
  // Передаємо екземпляр ApiService для виконання запитів до сервера.
  const LoginScreen({Key? key, required this.api}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Контролери для керування текстом у полях введення (email та пароль).
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Базова валідація на боці клієнта: перевіряємо, чи не пусті поля.
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Заповніть всі поля"), backgroundColor: Colors.red),
      );
      return;
    }

    // Асинхронний виклик методу loginUser.
    // Ключове слово await чекає відповіді від сервера, не блокуючи UI.
    final success = await widget.api.loginUser(email, password);

    if (success) {
      // Якщо вхід успішний, замінюємо поточний екран на головний.
      // pushReplacement використовується, щоб користувач не міг повернутися на логін кнопкою "Назад".
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationWrapper(api: widget.api),
        ),
      );
    } else {
      // Відображення помилки користувачеві.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Невірний email або пароль"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // ListView використовується замість Column, щоб екран можна було скролити,
          // коли відкривається клавіатура і перекриває поля.
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E2A3A),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.attach_money, color: Colors.white, size: 40),
                  width: 64, height: 64,
                ),
              ),
              SizedBox(height: 24),
              Text("Ласкаво просимо", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Введіть email та пароль", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 32),

              Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "user@example.com",
                  prefixIcon: Icon(Icons.email, color: Colors.grey),
                  fillColor: Color(0xFFF6F7F9),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 20),

              Text("Пароль", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true, // Приховує введені символи (зірочки/крапки)
                decoration: InputDecoration(
                  hintText: "••••••••",
                  prefixIcon: Icon(Icons.lock, color: Colors.grey),
                  fillColor: Color(0xFFF6F7F9),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen())),
                  child: Text("Забули пароль?", style: TextStyle(color: Colors.black)),
                ),
              ),
              SizedBox(height: 12),

              ElevatedButton(
                onPressed: _login, // Виклик функції авторизації
                child: Text("Увійти", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E2A3A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Немає акаунту? "),
                  TextButton(
                    // Перехід на екран реєстрації
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())),
                    child: Text("Зареєструватися", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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