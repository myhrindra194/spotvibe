class User {
  String id;
  String email;
  String name;

  User({
    required this.id,
    required this.email,
    required this.name,
  });

  factory User.fromMap(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      email: data['email'],
      name: data['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
    };
  }
}
