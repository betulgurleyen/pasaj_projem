import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_styles.dart';

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
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Her 3 saniyede bir yeni mesaj kontrol et
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(silent: true);
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final msgs = await ApiService.getMessages(widget.otherUserId);
      if (mounted) {
        setState(() {
          _messages = msgs.map((m) => Map<String, dynamic>.from(m)).toList();
          if (!silent) _loading = false;
        });
        if (!silent) _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final optimistic = {
      'sender_id': widget.currentUserId,
      'receiver_id': widget.otherUserId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(optimistic);
      _sending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      await ApiService.sendMessage(widget.otherUserId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mesaj gönderilemedi: $e')));
      }
    }

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
    _pollTimer?.cancel();
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
                                msg['sender_id'] == widget.currentUserId ||
                                msg['sender_id'].toString() ==
                                    widget.currentUserId.toString();
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
