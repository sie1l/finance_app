import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Контролери для зчитування тексту, введеного користувачем
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Змінна стану для відображення індикатора завантаження під час запиту до API
  bool _isLoading = false;

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    // Первинна валідація даних на стороні клієнта (чи не пусті поля)
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Заповніть всі поля"), backgroundColor: Colors.red),
      );
      return;
    }

    // Перевірка на співпадіння паролів
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Паролі не співпадають"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true); // Блокуємо кнопку і показуємо спінер

    // Отримуємо доступ до ApiService через Provider.
    // listen: false використовується, бо нам потрібно лише викликати метод, а не слухати зміни стану.
    final api = Provider.of<ApiService>(context, listen: false);

    // Асинхронний виклик реєстрації
    final success = await api.registerUser(email, password);

    setState(() => _isLoading = false); // Прибираємо спінер

    if (success) {
      // Якщо реєстрація успішна — переходимо на екран підтвердження пошти
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(email: email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Помилка реєстрації. Можливо, email вже зайнятий."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
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
            Text("Створити акаунт", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Заповніть дані для реєстрації", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 32),

            _buildTextField("Електронна пошта", "user@example.com", controller: _emailController, keyboardType: TextInputType.emailAddress, icon: Icons.email),
            SizedBox(height: 20),

            _buildTextField("Пароль", "••••••••", controller: _passwordController, isPassword: true, icon: Icons.lock),
            SizedBox(height: 8),
            Text("Мінімум 8 символів", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            SizedBox(height: 20),

            _buildTextField("Підтвердіть пароль", "••••••••", controller: _confirmPasswordController, isPassword: true, icon: Icons.lock_outline),

            SizedBox(height: 24),

            // Показуємо CircularProgressIndicator, якщо йде запит, інакше — кнопку
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _register,
              child: Text("Зареєструватися", style: TextStyle(fontSize: 18)),
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
                Text("Вже є акаунт? "),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Увійти", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Допоміжний метод (Refactoring) для створення однакових полів вводу,
  // щоб не дублювати код верстки тричі.
  Widget _buildTextField(String label, String hintText, {bool isPassword = false, TextInputType keyboardType = TextInputType.text, required TextEditingController controller, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            fillColor: Color(0xFFF6F7F9),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}