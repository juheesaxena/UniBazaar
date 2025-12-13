import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          "https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app",
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(
          "Inbox",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 1,
      ),
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
              return t2.compareTo(t1);
            });

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = Map<dynamic, dynamic>.from(chats[index].value);

              final peerUid = chat["uid"] ?? "";
              final peerName = chat["name"] ?? "User";
              final lastMessage = chat["lastMessage"] ?? "";
              final unread = (chat["unread"] ?? 0) as int;

              final avatarLetter =
                  peerName.isNotEmpty ? peerName[0].toUpperCase() : "U";

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(peerUid: peerUid, peerName: peerName),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // AVATAR
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _avatarColor(index),
                        child: Text(
                          avatarLetter,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // NAME + MESSAGE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // UNREAD BADGE
                      if (unread > 0)
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8BC34A), // soft green
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Simple pastel avatar colors
  Color _avatarColor(int index) {
    const colors = [
      Color(0xFFFFCDD2), // pink
      Color(0xFFFFF9C4), // yellow
      Color(0xFFBBDEFB), // blue
      Color(0xFFC8E6C9), // green
    ];
    return colors[index % colors.length];
  }
}
