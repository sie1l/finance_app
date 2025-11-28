import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

// Головний віджет-обгортка, який реалізує нижню навігацію.
// Він відповідає за перемикання між основними розділами додатку (Головна, Транзакції, Статистика, Профіль).
class MainNavigationWrapper extends StatefulWidget {
  final ApiService api;
  const MainNavigationWrapper({Key? key, required this.api}) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0; // Зберігає індекс поточної активної вкладки

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Ініціалізація списку сторінок.
    // Ми створюємо їх один раз при запуску, щоб зберегти їхній стан.
    _pages = [
      HomeScreen(api: widget.api),
      TransactionsScreen(),
      StatisticsScreen(),
      ProfileScreen(),
    ];
  }

  // Метод для оновлення інтерфейсу при натисканні на вкладку
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // Змінюємо індекс, що викликає перебудову віджета
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Відображаємо сторінку зі списку відповідно до обраного індексу
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,

        // type: BottomNavigationBarType.fixed — важливо для 4 і більше елементів,
        // щоб іконки не зсувалися і підписи завжди були видимі.
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Головна',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Транзакції',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профіль',
          ),
        ],
      ),
    );
  }
}