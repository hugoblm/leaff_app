class User {
  final String id;
  final String email;
  final String? address;
  final String? habits;
  final bool notifications;

  User({
    required this.id,
    required this.email,
    this.address,
    this.habits,
    this.notifications = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      address: json['address'] as String?,
      habits: json['habits'] as String?,
      notifications: json['notifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'address': address,
        'habits': habits,
        'notifications': notifications,
      };
} 