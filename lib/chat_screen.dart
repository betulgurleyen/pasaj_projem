import 'dart:async';
import 'package:flutter/material.dart';
import 'db_service.dart';
import 'app_styles.dart';
import 'package:postgres/postgres.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final int otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = DatabaseService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadHistory();
    _subscribeToLive();
  }

  Future<void> _loadHistory() async {
    final msgs = await _db.getMessages(
      userId1: widget.currentUserId,
      userId2: widget.otherUserId,
    );

    // ✅ YENİ: Bana gelen mesajları okundu olarak işaretle
    await _markAsRead();

    if (mounted) {
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _markAsRead() async {
    final conn = await DatabaseService.connect();
    await conn.execute(
      Sql.named(
        'UPDATE messages SET is_read = true '
        'WHERE receiver_id = @me AND sender_id = @other AND is_read = false',
      ),
      parameters: {'me': widget.currentUserId, 'other': widget.otherUserId},
    );
  }

  void _subscribeToLive() {
    _sub = _db.listenForMessages().listen((data) {
      final sender = data['sender_id'];
      final receiver = data['receiver_id'];

      final belongs =
          (sender == widget.currentUserId && receiver == widget.otherUserId) ||
          (sender == widget.otherUserId && receiver == widget.currentUserId);

      // Kendi gönderdiğimiz mesaj zaten optimistic olarak eklendi, tekrar ekleme
      final alreadyAdded = sender == widget.currentUserId;

      if (belongs && !alreadyAdded && mounted) {
        setState(() => _messages.add(data));
        _scrollToBottom();
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    // Optimistic UI: gönderilmeden önce ekrana yansıt
    final optimistic = {
      'sender_id': widget.currentUserId,
      'receiver_id': widget.otherUserId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
      'sender_name': 'Sen',
    };

    setState(() {
      _messages.add(optimistic);
      _sending = true;
    });
    _controller.clear();
    _scrollToBottom();

    await _db.sendMessage(
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      content: text,
    );

    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppStyles.accentPeach,
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz mesaj yok.\nİlk mesajı sen gönder!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];
                            final isMe =
                                msg['sender_id'] == widget.currentUserId;
                            return _Bubble(
                              content: msg['content']?.toString() ?? '',
                              isMe: isMe,
                              rawTime: msg['created_at']?.toString() ?? '',
                            );
                          },
                        ),
                ),
                _InputBar(
                  controller: _controller,
                  sending: _sending,
                  onSend: _send,
                ),
              ],
            ),
    );
  }
}

// ── Mesaj baloncuğu ──────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String rawTime;

  const _Bubble({
    required this.content,
    required this.isMe,
    required this.rawTime,
  });

  String get _time {
    try {
      final dt = DateTime.parse(rawTime).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppStyles.accentPeach : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _time,
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Giriş çubuğu ────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Mesaj yaz...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: AppStyles.accentPeach),
            ),
          ],
        ),
      ),
    );
  }
}
