import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String peerUid;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.peerUid,
    required this.peerName,
  });

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
    final avatarInitial =
        widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                avatarInitial,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.peerName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),

      // ---------------- BODY ----------------
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        Map<dynamic, dynamic>.from(messages[index].value);

                    final isMe = msg["fromUid"] == _currentUid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFB7DFA3) // light green
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          msg["text"],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---------------- INPUT BAR ----------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.black),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Message",
                          border: InputBorder.none,
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
            ),
          ),
        ],
      ),
    );
  }
}
