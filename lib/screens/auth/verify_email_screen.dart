import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../main_navigation_wrapper.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  // Отримуємо email через конструктор, щоб знати, куди саме відправляти код або запит на повторну відправку.
  const VerifyEmailScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  void _verify() async {
    final code = _codeController.text.trim();

    // Валідація на стороні клієнта: код обов'язково має складатися з 6 цифр.
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Код має містити 6 цифр"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);

    // Асинхронний виклик API для перевірки коду.
    final success = await api.verifyEmail(widget.email, code);
    setState(() => _isLoading = false);

    if (success) {
      // Перевірка mounted потрібна, щоб переконатися, що віджет все ще існує перед використанням контексту.
      if (!mounted) return;

      // Логіка навігації після успішної верифікації:
      if (api.isAuthenticated) {
        // Якщо API відразу повертає токен — переходимо на Головний екран.
        // pushAndRemoveUntil((route) => false) очищує історію, щоб користувач не міг натиснути "Назад".
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainNavigationWrapper(api: api)),
              (route) => false,
        );
      } else {
        // Якщо токен не прийшов — направляємо користувача на екран Логіну.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Пошта підтверджена! Увійдіть."), backgroundColor: Colors.green),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen(api: api)),
              (route) => false,
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Невірний код"), backgroundColor: Colors.red),
      );
    }
  }

  // Метод для повторної відправки коду, якщо перший лист не прийшов.
  void _resendCode() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final success = await api.resendCode(widget.email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Код відправлено повторно" : "Помилка відправки"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.mark_email_read, color: Colors.black, size: 40),
                  width: 64, height: 64,
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Підтвердження пошти",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Ми надіслали 6-значний код на\n${widget.email}",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),

              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6, // Обмеження довжини вводу
                style: TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                // FilteringTextInputFormatter дозволяє вводити тільки цифри, блокуючи літери та символи.
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: "", // Приховує лічильник символів
                  hintText: "------",
                  fillColor: Color(0xFFF6F7F9),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _verify,
                child: Text("Підтвердити", style: TextStyle(fontSize: 18)),
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
                  Text("Не отримали код? "),
                  TextButton(
                    onPressed: _resendCode,
                    child: Text("Надіслати ще раз", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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