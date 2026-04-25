import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'db_service.dart';
import 'chat_screen.dart';
import 'package:postgres/postgres.dart';

class InboxScreen extends StatefulWidget {
  final int currentUserId;

  const InboxScreen({super.key, required this.currentUserId});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  // Kullanıcının konuştuğu kişileri getir (her kişiden son mesaj)
  Future<List<Map<String, dynamic>>> _fetchConversations() async {
    final conn = await DatabaseService.connect();

    final result = await conn.execute(
      Sql.named('''
        SELECT DISTINCT ON (other_id)
          other_id,
          other_name,
          last_message,
          last_time,
          unread_count
        FROM (
          SELECT
            CASE 
              WHEN m.sender_id = @uid THEN m.receiver_id 
              ELSE m.sender_id 
            END AS other_id,
            up.full_name AS other_name,
            m.content AS last_message,
            m.created_at AS last_time,
            COUNT(CASE WHEN m.is_read = false AND m.receiver_id = @uid THEN 1 END)
              OVER (PARTITION BY 
                CASE WHEN m.sender_id = @uid THEN m.receiver_id ELSE m.sender_id END
              ) AS unread_count
          FROM messages m
          JOIN user_profiles up ON up.user_id = 
            CASE WHEN m.sender_id = @uid THEN m.receiver_id ELSE m.sender_id END
          WHERE m.sender_id = @uid OR m.receiver_id = @uid
          ORDER BY m.created_at DESC
        ) sub
        ORDER BY other_id, last_time DESC
      '''),
      parameters: {'uid': widget.currentUserId},
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz mesajınız yok.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!;

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherId = conv['other_id'] as int;
              final otherName = conv['other_name']?.toString() ?? 'Kullanıcı';
              final lastMessage = conv['last_message']?.toString() ?? '';
              final unread = int.tryParse(conv['unread_count'].toString()) ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppStyles.primaryGreen,
                  radius: 26,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  otherName,
                  style: TextStyle(
                    fontWeight: unread > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread > 0 ? Colors.black87 : Colors.grey,
                  ),
                ),
                trailing: unread > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: AppStyles.accentPeach,
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        currentUserId: widget.currentUserId,
                        otherUserId: otherId,
                        otherUserName: otherName,
                      ),
                    ),
                  );
                  // Dönünce listeyi yenile
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}
