class DashboardStats {
  final double currentBalance;
  final double lastMonthIncome;
  final double lastMonthExpenses;

  DashboardStats({
    required this.currentBalance,
    required this.lastMonthIncome,
    required this.lastMonthExpenses,
  });

  // Фабричний метод для обробки JSON-відповіді із сервера.
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      // (json[...] as num).toDouble() — це безпечне приведення типів.
      // Потрібно, бо API може повернути ціле число (int), а програма очікує дробове (double).
      currentBalance: (json['current_balance'] as num).toDouble(),
      lastMonthIncome: (json['last_month_income'] as num).toDouble(),
      lastMonthExpenses: (json['last_month_expenses'] as num).toDouble(),
    );
  }
}