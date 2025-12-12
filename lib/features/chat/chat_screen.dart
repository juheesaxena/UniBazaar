import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String peerUid;
  final String peerName;

  const ChatScreen({super.key, required this.peerUid, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService.instance;
  final TextEditingController _controller = TextEditingController();

  late final String _currentUid;
  late final String _chatId;

  @override
  void initState() {
    super.initState();

    _chatService.init();

    _currentUid = FirebaseAuth.instance.currentUser!.uid;
    _chatId = _chatService.chatIdFor(_currentUid, widget.peerUid);

    _chatService.markChatAsRead(_chatId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatService.messageStream(_chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.snapshot.value;

                if (data == null || data is! Map) {
                  return const Center(child: Text("Say hi 👋"));
                }

                final raw = Map<dynamic, dynamic>.from(data);

                final messages = raw.entries.toList()
                  ..sort((a, b) {
                    final t1 = (a.value["timestamp"] ?? 0) as int;
                    final t2 = (b.value["timestamp"] ?? 0) as int;
                    return t1.compareTo(t2);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = Map<dynamic, dynamic>.from(
                      messages[index].value,
                    );

                    final isMe = msg["fromUid"] == _currentUid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg["text"]),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT BAR
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;

                    _controller.clear();

                    await _chatService.sendMessage(
                      toUid: widget.peerUid,
                      text: text,
                      toName: widget.peerName,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
