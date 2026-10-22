class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  factory UserAccount.fromMap(Map<String, Object?> map) => UserAccount(
        id: map['id'] as int,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
