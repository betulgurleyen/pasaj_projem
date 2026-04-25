import 'dart:async';
import 'dart:convert';
import 'package:postgres/postgres.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _host = 'localhost';
  static const String _dbName = 'pasaj_db';
  static const int _port = 5432;
  static const String _user = 'postgres';
  static const String _pass = 'bil123';

  Connection? _connection;

  Future<Connection> get connection async {
    if (_connection == null || _connection!.isOpen == false) {
      _connection = await Connection.open(
        Endpoint(
          host: _host,
          database: _dbName,
          username: _user,
          password: _pass,
          port: _port,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );
    }
    return _connection!;
  }

  // Eski static connect() metodunu bozmamak için geride bırak
  static Future<Connection> connect() async {
    return await DatabaseService().connection;
  }

  // ── MESAJLAŞMA ──────────────────────────────────────────────

  Future<void> sendMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) async {
    final conn = await connection;
    await conn.execute(
      Sql.named(
        'INSERT INTO messages (sender_id, receiver_id, content) '
        'VALUES (@sender, @receiver, @content)',
      ),
      parameters: {
        'sender': senderId,
        'receiver': receiverId,
        'content': content,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required int userId1,
    required int userId2,
  }) async {
    final conn = await connection;
    final result = await conn.execute(
      Sql.named(
        'SELECT m.id, m.sender_id, m.receiver_id, m.content, '
        '       m.created_at, up.full_name AS sender_name '
        'FROM messages m '
        'JOIN user_profiles up ON up.user_id = m.sender_id '
        'WHERE (m.sender_id = @u1 AND m.receiver_id = @u2) '
        '   OR (m.sender_id = @u2 AND m.receiver_id = @u1) '
        'ORDER BY m.created_at ASC',
      ),
      parameters: {'u1': userId1, 'u2': userId2},
    );
    return result.map((row) => row.toColumnMap()).toList();
  }

  Stream<Map<String, dynamic>> listenForMessages() async* {
    final conn = await connection;
    await conn.execute('LISTEN new_message');

    await for (final notification in conn.channels.all) {
      if (notification.channel == 'new_message') {
        try {
          final data =
              jsonDecode(notification.payload ?? '{}') as Map<String, dynamic>;
          yield data;
        } catch (_) {}
      }
    }
  }
}
