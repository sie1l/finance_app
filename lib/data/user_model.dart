class UserModel {
  final int id;
  final String email;

  UserModel({
    required this.id,
    required this.email,
  });

  // Створює об'єкт користувача з JSON (наприклад, з даних, отриманих після авторизації).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
    );
  }

  // Перетворює об'єкт у JSON (стандартний метод для серіалізації даних).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
    };
  }
}