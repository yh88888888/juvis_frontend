class SessionUser {
  final int id;
  final String username;
  final String? name;
  final String role;
  final String jwt;

  SessionUser({
    required this.id,
    required this.username,
    this.name,
    required this.role,
    required this.jwt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name': name,
    'role': role,
    'jwt': jwt,
  };

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      jwt: json['jwt'] as String,
      //     서버에서 JWT를 어디에 넣어주는지에 따라
      //     json['jwt'] 부분은 json['body']['jwt'] 이런 식으로 살짝 바꿔야 할 수도 있음.
      // (지금은 body 안에 jwt 필드 있다고 가정한 상태)
    );
  }
}
