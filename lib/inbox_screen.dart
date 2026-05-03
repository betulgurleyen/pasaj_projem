import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'api_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final int currentUserId;

  const InboxScreen({super.key, required this.currentUserId});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  Future<List<dynamic>> _fetchConversations() async {
    return await ApiService.getInbox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: AppStyles.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
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
              final otherId = conv['other_id'] is int
                  ? conv['other_id']
                  : int.tryParse(conv['other_id'].toString()) ?? 0;
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
