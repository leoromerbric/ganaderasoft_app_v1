class User {
  final int id;
  final String name;
  final String email;
  final String typeUser;
  final String image;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.typeUser,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      typeUser: json['type_user'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type_user': typeUser,
      'image': image,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final User user;
  final String token;
  final String tokenType;

  LoginResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      message: json['message'],
      user: User.fromJson(json['data']['user']),
      token: json['data']['token'],
      tokenType: json['data']['token_type'],
    );
  }
}