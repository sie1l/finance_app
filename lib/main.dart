import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_wrapper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider створює екземпляр ApiService на самому верху дерева віджетів.
    // Це дозволяє отримувати доступ до API та даних користувача з будь-якого екрана.
    return ChangeNotifierProvider(
      create: (context) => ApiService(),
      child: MaterialApp(
        title: 'Finance App',
        debugShowCheckedModeBanner: false,

        // Налаштування локалізації.
        // Це необхідно для того, щоб стандартні віджети (наприклад, календар) відображалися українською мовою.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('uk', 'UA'), // Підтримка української локалі
        ],

        // Замість конкретного екрана ми запускаємо обгортку перевірки авторизації
        home: const AuthCheckWrapper(),
      ),
    );
  }
}

// Віджет, який вирішує, куди направити користувача при запуску додатка.
class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({Key? key}) : super(key: key);

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  bool _isChecking = true; // Стан завантаження (перевірки токена)

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  // Перевірка наявності збереженої сесії (авто-логін)
  void _checkSession() async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.tryAutoLogin(); // Метод з ApiService, що читає SecureStorage

    if (mounted) {
      setState(() {
        _isChecking = false; // Перевірка завершена
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Поки йде перевірка — показуємо екран завантаження (сплеш-скрін)
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Color(0xFF1E2A3A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Коли перевірка завершена, дивимось на статус авторизації
    return Consumer<ApiService>(
      builder: (context, api, child) {
        if (api.isAuthenticated) {
          return MainNavigationWrapper(api: api); // Якщо увійшов -> Головна
        } else {
          return LoginScreen(api: api); // Якщо ні -> Екран входу
        }
      },
    );
  }
}