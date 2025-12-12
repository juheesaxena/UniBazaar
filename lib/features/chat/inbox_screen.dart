import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // ✅ FIX: Fully compatible version
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          "https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app",
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: StreamBuilder<DatabaseEvent>(
        stream: db.ref("userChats/$uid").onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.snapshot.value;

          if (data == null || data is! Map) {
            return const Center(child: Text("No chats yet"));
          }

          final chats = Map<dynamic, dynamic>.from(data).entries.toList()
            ..sort((a, b) {
              final t1 = (a.value['timestamp'] ?? 0) as int;
              final t2 = (b.value['timestamp'] ?? 0) as int;
              return t2.compareTo(t1); // latest first
            });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = Map<dynamic, dynamic>.from(chats[index].value);

              final peerUid = chat["uid"] ?? "";
              final peerName = chat["name"] ?? "User";
              final lastMessage = chat["lastMessage"] ?? "";
              final unread = (chat["unread"] ?? 0) as int;

              return ListTile(
                title: Text(peerName),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: unread > 0 ? _UnreadBadge(count: unread) : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(peerUid: peerUid, peerName: peerName),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text("$count", style: const TextStyle(color: Colors.white)),
    );
  }
}
