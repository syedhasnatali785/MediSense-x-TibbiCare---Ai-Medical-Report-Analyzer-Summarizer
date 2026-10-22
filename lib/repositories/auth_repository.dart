import 'dart:convert';

import 'package:aimedicalreportanalyzer/models/user_account.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'offline_auth.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE active_session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            user_email TEXT,
            last_login INTEGER
          )
        ''');
      },
    );
  }

  String hashPassword(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  Future<UserAccount?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanedName = name.trim();
    final cleanedEmail = email.trim().toLowerCase();
    if (cleanedName.isEmpty || cleanedEmail.isEmpty || password.trim().isEmpty) {
      throw const FormatException('Please fill in all fields.');
    }

    final db = await database;
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanedEmail],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw const FormatException('An account with this email already exists.');
    }

    final createdAt = DateTime.now();
    final id = await db.insert('users', {
      'name': cleanedName,
      'email': cleanedEmail,
      'password_hash': hashPassword(password),
      'created_at': createdAt.millisecondsSinceEpoch,
    });

    final user = UserAccount(
      id: id,
      name: cleanedName,
      email: cleanedEmail,
      passwordHash: hashPassword(password),
      createdAt: createdAt,
    );

    await _setSession(user.email);
    return user;
  }

  Future<UserAccount?> login({
    required String email,
    required String password,
  }) async {
    final cleanedEmail = email.trim().toLowerCase();
    if (cleanedEmail.isEmpty || password.trim().isEmpty) {
      throw const FormatException('Email and password are required.');
    }

    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanedEmail],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const FormatException('No user found for this email.');
    }

    final user = UserAccount.fromMap(rows.first);
    final passwordHash = hashPassword(password);
    if (user.passwordHash != passwordHash) {
      throw const FormatException('Incorrect password.');
    }

    await _setSession(user.email);
    return user;
  }

  Future<UserAccount?> getCurrentUser() async {
    final db = await database;
    final rows = await db.query('active_session', limit: 1);
    if (rows.isEmpty || rows.first['user_email'] == null) {
      return null;
    }
    final email = rows.first['user_email'] as String;
    final userRows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (userRows.isEmpty) {
      await clearSession();
      return null;
    }
    return UserAccount.fromMap(userRows.first);
  }

  Future<void> logout() async {
    await clearSession();
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('active_session');
  }

  Future<void> _setSession(String email) async {
    final db = await database;
    await db.delete('active_session');
    await db.insert(
      'active_session',
      {
        'id': 1,
        'user_email': email,
        'last_login': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
