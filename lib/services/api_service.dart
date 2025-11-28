import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/transaction_model.dart';
import '../data/category_model.dart';
import '../data/user_model.dart';
import '../data/statistics_models.dart';
import '../data/dashboard_stats.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ChangeNotifier дозволяє повідомляти UI про зміни (наприклад, коли користувач увійшов/вийшов),
// щоб екрани автоматично оновлювались.
class ApiService with ChangeNotifier {
  final String baseUrl = 'https://okane.x0ryz.cc';

  // Використовуємо SecureStorage для зберігання токенів у зашифрованому вигляді
  // (Keychain на iOS, Keystore на Android).
  final _storage = const FlutterSecureStorage();

  UserModel? _currentUser;
  String? _accessToken; // Токен для доступу до даних (живе недовго)
  String? _refreshTokenCookie; // Токен для оновлення сесії (живе довго)

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  // Метод для автоматичного входу при запуску додатку.
  // Перевіряє, чи є збережені токени на пристрої.
  Future<bool> tryAutoLogin() async {
    final storedCookie = await _storage.read(key: 'refresh_token');
    final storedUser = await _storage.read(key: 'user_data');

    if (storedCookie == null || storedUser == null) {
      return false;
    }

    try {
      _refreshTokenCookie = storedCookie;
      _currentUser = UserModel.fromJson(jsonDecode(storedUser));

      // Пробуємо оновити access токен, щоб переконатися, що сесія активна
      final success = await _refreshToken();

      if (success) {
        notifyListeners();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      print("Auto login error: $e");
      return false;
    }
  }

  Future<void> _saveSession() async {
    if (_refreshTokenCookie != null) {
      await _storage.write(key: 'refresh_token', value: _refreshTokenCookie);
    }
    if (_currentUser != null) {
      await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toJson()));
    }
  }

  Future<bool> registerUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    final url = Uri.parse('$baseUrl/auth/verify');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty && response.body != '{}') {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          if (data.containsKey('access_token')) {
            _accessToken = data['access_token'];
            if (data.containsKey('user')) {
              _currentUser = UserModel.fromJson(data['user']);
            }
            _extractCookie(response);
            await _saveSession();
            notifyListeners(); // Оновлюємо UI (переходимо на головний екран)
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Verify error: $e');
      return false;
    }
  }

  Future<bool> resendCode(String email) async {
    final url = Uri.parse('$baseUrl/auth/resend');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _accessToken = data['access_token'];
        _currentUser = UserModel.fromJson(data['user']);
        _extractCookie(response);
        await _saveSession();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (_refreshTokenCookie != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {'Content-Type': 'application/json', 'Cookie': _refreshTokenCookie!},
        );
      } catch (_) {}
    }
    _accessToken = null;
    _refreshTokenCookie = null;
    _currentUser = null;
    await _storage.deleteAll(); // Очищаємо захищене сховище
    notifyListeners();
  }

  // Метод оновлення токена. Викликається автоматично, якщо access_token застарів (401 помилка).
  Future<bool> _refreshToken() async {
    if (_refreshTokenCookie == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json', 'Cookie': _refreshTokenCookie!},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token']; // Отримуємо новий ключ доступу
        notifyListeners();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void _extractCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null && rawCookie.contains('user_refresh_token')) {
      _refreshTokenCookie = rawCookie;
    }
  }

  // Головний метод-обгортка для всіх запитів до API.
  // Він автоматично додає Bearer Token і обробляє помилку 401 (Unauthorized).
  Future<http.Response> authenticatedRequest(String method, String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    if (_accessToken == null) throw Exception('No access token');

    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken', // Додаємо токен
    };

    http.Response response;

    if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: jsonEncode(body));
    } else if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers);
    } else if (method == 'PATCH') {
      response = await http.patch(uri, headers: headers, body: jsonEncode(body));
    } else {
      throw Exception('Method not supported');
    }

    // Логіка оновлення токена:
    // Якщо сервер відповів 401, ми пробуємо оновити токен (_refreshToken)
    // і повторити запит з новим токеном.
    if (response.statusCode == 401) {
      if (await _refreshToken()) {
        headers['Authorization'] = 'Bearer $_accessToken';
        if (method == 'POST') {
          response = await http.post(uri, headers: headers, body: jsonEncode(body));
        } else if (method == 'GET') {
          response = await http.get(uri, headers: headers);
        } else if (method == 'DELETE') {
          response = await http.delete(uri, headers: headers);
        } else if (method == 'PATCH') {
          response = await http.patch(uri, headers: headers, body: jsonEncode(body));
        }
      }
    }
    return response;
  }

  Future<DashboardStats?> getDashboardStats() async {
    if (!isAuthenticated) return null;
    try {
      final response = await authenticatedRequest('GET', '/statistics/dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return DashboardStats.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Dashboard stats error: $e');
      return null;
    }
  }


  Future<List<TransactionModel>> getTransactions() async {
    if (!isAuthenticated) return [];
    try {
      final response = await authenticatedRequest('GET', '/transactions/');
      if (response.statusCode == 200) {
        // utf8.decode обов'язковий для коректного відображення кирилиці (укр. мови)
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = data.map((json) => TransactionModel.fromJson(json)).toList();
        list.sort((a, b) => b.date.compareTo(a.date)); // Сортування за датою (нові зверху)
        return list;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addTransaction(String type, double amount, String name, int categoryId, DateTime date) async {
    try {
      final body = {
        'type': type,
        'name': name,
        'amount': amount,
        'category_id': categoryId,
        'date': date.toIso8601String(),
      };
      final response = await authenticatedRequest('POST', '/transactions/', body: body);
      if (response.statusCode == 200) {
        notifyListeners(); // Повідомляємо UI, що дані змінилися
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTransaction(int id, {required String type, required double amount, required String name, required int categoryId, required DateTime date}) async {
    try {
      final body = {
        'type': type,
        'name': name,
        'amount': amount,
        'category_id': categoryId,
        'date': date.toIso8601String(),
      };
      final response = await authenticatedRequest('PATCH', '/transactions/$id', body: body);
      if (response.statusCode == 200) {
        notifyListeners();
        return true;
      }
      print('Update failed: ${response.body}');
      return false;
    } catch (e) {
      print('Update error: $e');
      return false;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final response = await authenticatedRequest('DELETE', '/transactions/$id');
      if (response.statusCode == 204) notifyListeners();
    } catch (_) {}
  }


  Future<List<CategoryModel>> getCategories(String type) async {
    if (!isAuthenticated) return [];

    try {
      final response = await authenticatedRequest('GET', '/categories/');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        return data.map<CategoryModel>((json) {
          return CategoryModel.fromJson(json);
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get categories exception: $e');
      return [];
    }
  }

  Future<void> addCategory(CategoryModel c) async {
    try {
      final body = {
        'name': c.name,
        'icon': c.icon,
        'color': c.colorHex,
      };

      final response = await authenticatedRequest('POST', '/categories/', body: body);

      if (response.statusCode == 201) {
        notifyListeners();
      } else {
        print('Add category error: ${response.body}');
      }
    } catch (e) {
      print('Add category exception: $e');
    }
  }
  Future<List<CategoryStat>> getCategoryStatistics(DateTime startDate, DateTime endDate) async {
    if (!isAuthenticated) return [];
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      };

      final response = await authenticatedRequest('GET', '/statistics/categories', queryParams: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => CategoryStat.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DailyStat>> getHistoryStatistics(DateTime startDate, DateTime endDate) async {
    if (!isAuthenticated) return [];
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      };

      final response = await authenticatedRequest('GET', '/statistics/history', queryParams: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => DailyStat.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Map<String, int> _generateCategoryStyle(String name) {
    final colors = [Colors.blue.value, Colors.red.value, Colors.green.value, Colors.orange.value, Colors.purple.value];
    final icons = [Icons.category.codePoint, Icons.shopping_bag.codePoint, Icons.home.codePoint, Icons.fastfood.codePoint];
    int hash = name.codeUnits.fold(0, (p, e) => p + e);
    return {'color': colors[hash % colors.length], 'icon': icons[hash % icons.length]};
  }
}