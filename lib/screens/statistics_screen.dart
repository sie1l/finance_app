import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Пакет для графіків
import 'package:intl/intl.dart';
import '../data/statistics_models.dart';
import '../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedIndex = 0; // Індекс обраної кнопки (0 - Місяць, 1 - Тиждень...)
  String _currentFilter = 'month'; // Текстове значення фільтру для логіки

  // Діапазон дат, за який ми запитуємо статистику
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateDateRange(); // Ініціалізація дат при старті
  }

  // Метод для обчислення діапазону дат залежно від обраного фільтру.
  // Викликається щоразу при зміні вкладки (ToggleButtons).
  void _updateDateRange() {
    final now = DateTime.now();
    if (_currentFilter == 'week') {
      _endDate = now;
      _startDate = now.subtract(Duration(days: 6)); // Останні 7 днів
    } else if (_currentFilter == 'month') {
      _startDate = DateTime(now.year, now.month, 1); // Перший день місяця
      _endDate = DateTime(now.year, now.month + 1, 0); // Останній день місяця
    } else if (_currentFilter == 'year') {
      _startDate = DateTime(now.year, 1, 1); // Початок року
      _endDate = DateTime(now.year, 12, 31); // Кінець року
    }
    setState(() {}); // Оновлюємо UI, що запустить нові запити до API
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        return Scaffold(
          backgroundColor: Color(0xFFF6F7F9),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Color(0xFFF6F7F9),
            title: Text("Статистика",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilters(), // Кнопки перемикання періоду
                  SizedBox(height: 20),

                  // FutureBuilder для графіка (динаміка витрат).
                  // Завантажує дані історії (DailyStat) за обраний період.
                  FutureBuilder<List<DailyStat>>(
                    future: apiService.getHistoryStatistics(_startDate, _endDate),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 300,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final historyData = snapshot.data ?? [];
                      return Container(
                        height: 300,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Динаміка витрат",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                            SizedBox(height: 20),
                            Expanded(
                              child: _buildBarChart(historyData), // Побудова самого графіка
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 30),
                  Text("Структура витрат", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text("% від загальної суми", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 15),

                  // Другий FutureBuilder для списку категорій.
                  // Завантажує агреговані дані (CategoryStat).
                  FutureBuilder<List<CategoryStat>>(
                    future: apiService.getCategoryStatistics(_startDate, _endDate),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final categoryData = snapshot.data ?? [];
                      if (categoryData.isEmpty) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text("Даних немає", style: TextStyle(color: Colors.grey)),
                        ));
                      }

                      // Формування списку віджетів для кожної категорії
                      return Column(
                        children: categoryData.map((stat) {
                          final iconEmoji = stat.category.icon;
                          final colorObj = stat.category.color;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: _buildCategoryStatItem(
                              stat.category.name,
                              "${stat.percentage.toStringAsFixed(1)}%",
                              "₴${stat.totalAmount.toStringAsFixed(0)}",
                              iconEmoji,
                              stat.percentage / 100, // Значення для ProgressIndicator (0.0 - 1.0)
                              colorObj,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Логіка побудови стовпчикового графіка (найскладніша частина UI)
  Widget _buildBarChart(List<DailyStat> history) {
    List<BarChartGroupData> barGroups = [];
    double maxSpend = 0;

    // Логіка відображення для "Тижня"
    if (_currentFilter == 'week') {
      for (int i = 0; i < 7; i++) {
        DateTime targetDate = _startDate.add(Duration(days: i));

        // Шукаємо, чи є дані за цей день, інакше створюємо пустий запис
        final stat = history.firstWhere(
                (e) => isSameDay(e.date, targetDate),
            orElse: () => DailyStat(date: targetDate, income: 0, expense: 0)
        );

        if (stat.expense > maxSpend) maxSpend = stat.expense;

        barGroups.add(
          BarChartGroupData(
            x: i, // X - це індекс дня (0..6)
            barRods: [
              BarChartRodData(
                toY: stat.expense, // Y - це сума витрат
                color: stat.expense > 0 ? Color(0xFF1E2A3A) : Colors.transparent,
                width: 16,
                borderRadius: BorderRadius.circular(4),
                // Фон стовпчика (сірий)
                backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxSpend * 1.2, color: Colors.grey[100]),
              ),
            ],
          ),
        );
      }
    }
    // Логіка для "Місяця" (відображаємо кожен день місяця)
    else if (_currentFilter == 'month') {
      int daysInMonth = DateUtils.getDaysInMonth(_startDate.year, _startDate.month);

      for (int i = 1; i <= daysInMonth; i++) {
        final stat = history.firstWhere(
                (e) => e.date.day == i,
            orElse: () => DailyStat(date: DateTime(_startDate.year, _startDate.month, i), income: 0, expense: 0)
        );

        if (stat.expense > maxSpend) maxSpend = stat.expense;

        barGroups.add(
          BarChartGroupData(
            x: i, // X - день місяця (1..31)
            barRods: [
              BarChartRodData(
                toY: stat.expense,
                color: stat.expense > 0 ? Color(0xFF1E2A3A) : Colors.transparent,
                width: 6, // Тонші стовпчики, бо їх багато
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        );
      }
    }
    // Логіка для "Року" (агрегуємо дані по місяцях)
    else if (_currentFilter == 'year') {
      Map<int, double> monthlyData = {};
      for (var item in history) {
        // Сумуємо витрати для кожного місяця
        monthlyData[item.date.month] = (monthlyData[item.date.month] ?? 0) + item.expense;
      }

      for (int i = 1; i <= 12; i++) {
        double amount = monthlyData[i] ?? 0;
        if (amount > maxSpend) maxSpend = amount;

        barGroups.add(
          BarChartGroupData(
            x: i, // X - номер місяця (1..12)
            barRods: [
              BarChartRodData(
                toY: amount,
                color: amount > 0 ? Color(0xFF1E2A3A) : Colors.transparent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
    }

    if (maxSpend == 0) maxSpend = 100; // Щоб графік не ламався, якщо даних немає

    // Повертаємо віджет графіка з налаштуваннями осей та підписів
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSpend * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.round()} грн',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          // Налаштування нижніх підписів (Дні тижня / Числа / Місяці)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (_currentFilter == 'week') {
                  DateTime date = _startDate.add(Duration(days: value.toInt()));
                  // Форматуємо день тижня (Пн, Вт...) українською
                  String dayName = DateFormat.E('uk').format(date);
                  return Padding(padding: EdgeInsets.only(top: 5), child: Text(dayName, style: TextStyle(fontSize: 10)));
                }
                else if (_currentFilter == 'month') {
                  int day = value.toInt();
                  // Показуємо підписи тільки кожні 5 днів, щоб не нагромаджувати
                  if (day == 1 || day % 5 == 0) {
                    return Padding(padding: EdgeInsets.only(top: 5), child: Text(day.toString(), style: TextStyle(fontSize: 10)));
                  }
                  return SizedBox();
                }
                else {
                  const months = ['С', 'Л', 'Б', 'К', 'Т', 'Ч', 'Л', 'С', 'В', 'Ж', 'Л', 'Г'];
                  int monthIndex = value.toInt() - 1;
                  if (monthIndex >= 0 && monthIndex < 12) {
                    return Padding(padding: EdgeInsets.only(top: 5), child: Text(months[monthIndex], style: TextStyle(fontSize: 10)));
                  }
                  return SizedBox();
                }
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Ховаємо ліву вісь
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false), // Прибираємо сітку
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  // Віджет перемикачів (Місяць/Тиждень/Рік)
  Widget _buildFilters() {
    return Center(
      child: ToggleButtons(
        children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Місяць")),
          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Тиждень")),
          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Рік")),
        ],
        isSelected: [_selectedIndex == 0, _selectedIndex == 1, _selectedIndex == 2],
        onPressed: (int index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) _currentFilter = 'month';
            if (index == 1) _currentFilter = 'week';
            if (index == 2) _currentFilter = 'year';
            _updateDateRange(); // Оновлюємо дати при кліку
          });
        },
        borderRadius: BorderRadius.circular(10.0),
        selectedColor: Colors.white,
        fillColor: Color(0xFF1E2A3A),
        color: Colors.black,
        borderColor: Colors.grey[300],
        selectedBorderColor: Color(0xFF1E2A3A),
        constraints: BoxConstraints(minHeight: 40.0),
      ),
    );
  }

  // Віджет для відображення однієї категорії у списку
  Widget _buildCategoryStatItem(String title, String subtitle, String amount,
      String iconEmoji, double progress, Color progressColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: progressColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(iconEmoji, style: TextStyle(fontSize: 24)),
              ),
              SizedBox(width: 12),
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
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            ],
          ),
          SizedBox(height: 10),
          // Прогрес-бар (смужка)
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}