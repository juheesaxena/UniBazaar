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

  late final String _chatId;
  late final String _currentUid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid ?? '';
    _chatId = _chatService.chatIdFor(_currentUid, widget.peerUid);

    print("ChatScreen opened → peer: ${widget.peerName}");
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
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Say hi 👋"));
                }

                final raw =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final msgs = raw.entries.toList()
                  ..sort((a, b) {
                    final am = a.value as Map;
                    final bm = b.value as Map;
                    return (am['timestamp'] ?? 0).compareTo(
                      bm['timestamp'] ?? 0,
                    );
                  });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index].value as Map;
                    final isMe = m['fromUid'] == _currentUid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m['text']),
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
