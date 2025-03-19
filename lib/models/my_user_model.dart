class MyUser {
  String id;
  String email;
  String name;

  MyUser({
    required this.id,
    required this.email,
    required this.name,
  });

  factory MyUser.fromMap(Map<String, dynamic> data, String id) {
    return MyUser(
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
