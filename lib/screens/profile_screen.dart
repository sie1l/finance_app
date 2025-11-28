import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Використовуємо Consumer для доступу до ApiService.
    // Це дозволяє отримати дані поточного користувача (email, id) та викликати методи (наприклад, logout).
    return Consumer<ApiService>(
      builder: (context, api, child) {
        final user = api.currentUser;

        // Логіка відображення імені: якщо користувач є, беремо email, інакше "Гість".
        final displayName = user?.email ?? "Гість";
        final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

        return Scaffold(
          backgroundColor: Color(0xFFF6F7F9),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Color(0xFFF6F7F9),
            title: Text(
              "Профіль",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            automaticallyImplyLeading: false, // Приховує кнопку "Назад", бо це коренева вкладка
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                // Блок з аватаром (ініціали) та інформацією
                Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF1E2A3A),
                      child: Text(
                        initials,
                        style: TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      displayName,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),

                    if (user != null)
                      Text(
                        "ID: ${user.id}",
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                  ],
                ),

                SizedBox(height: 30),

                // Секції меню (візуальна частина)
                _buildSectionHeader("АКАУНТ"),
                SizedBox(height: 10),
                _buildProfileMenuItem(
                  "Особисті дані",
                  "Email та безпека",
                  Icons.person_outline,
                  Colors.blue,
                ),
                SizedBox(height: 10),
                _buildProfileMenuItem(
                  "Банківські рахунки",
                  "Керування рахунками",
                  Icons.account_balance_wallet_outlined,
                  Colors.green,
                ),
                SizedBox(height: 10),
                _buildProfileMenuItem(
                  "Безпека",
                  "Пароль, двофакторна автентифікація",
                  Icons.lock_outline,
                  Colors.purple,
                ),

                SizedBox(height: 30),

                _buildSectionHeader("НАЛАШТУВАННЯ"),
                SizedBox(height: 10),
                _buildProfileMenuItem(
                  "Сповіщення",
                  "Push, email сповіщення",
                  Icons.notifications_none,
                  Colors.orange,
                ),
                SizedBox(height: 10),
                _buildProfileMenuItem(
                  "Загальні налаштування",
                  "Мова, валюта, тема",
                  Icons.settings_outlined,
                  Colors.grey,
                ),

                SizedBox(height: 30),

                // Кнопка виходу з акаунту
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      "Вийти з акаунту",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    onTap: () async {
                      // Виклик методу logout в API (очищення токена)
                      await api.logout();

                      if (context.mounted) {
                        // Повне очищення історії навігації та перехід на екран входу
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen(api: api)),
                              (route) => false,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }

  // Допоміжний метод для створення однакових пунктів меню (Clean Code)
  Widget _buildProfileMenuItem(
      String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Тут можна додати навігацію на відповідні екрани
        },
      ),
    );
  }
}