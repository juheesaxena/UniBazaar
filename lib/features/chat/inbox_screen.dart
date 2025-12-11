import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:unibazaar/features/chat/chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  Future<String> _getUserName(String uid, FirebaseDatabase db) async {
    final snap = await db.ref("users/$uid/name").get();
    if (snap.exists && snap.value != null) {
      return snap.value.toString();
    }
    return "User";
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          "https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app",
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<DatabaseEvent>(
        stream: db.ref('userChats/$currentUid').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No chats yet'));
          }

          final raw = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final entries = raw.entries.toList()
            ..sort((a, b) {
              final am = a.value as Map;
              final bm = b.value as Map;
              return (bm['lastTimestamp'] ?? 0).compareTo(
                am['lastTimestamp'] ?? 0,
              );
            });

          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = entries[index].value as Map;
              final peerUid = chat['peerUid'];
              final storedName = (chat['peerName'] ?? "").toString();
              final lastMessage = chat['lastMessage'] ?? "";

              // If stored name is valid, use it directly
              if (storedName.isNotEmpty && storedName != "User") {
                return ListTile(
                  title: Text(storedName),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(peerUid: peerUid, peerName: storedName),
                      ),
                    );
                  },
                );
              }

              // Otherwise fetch correct name
              return FutureBuilder(
                future: _getUserName(peerUid, db),
                builder: (context, snap) {
                  final peerName = snap.data?.toString() ?? "User";

                  return ListTile(
                    title: Text(peerName),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
          );
        },
      ),
    );
  }
}
