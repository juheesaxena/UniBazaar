import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatService {
  ChatService._privateConstructor();
  static final ChatService instance = ChatService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // -------- CHAT ID --------
  String chatIdFor(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // -------- STREAM MESSAGES --------
  Stream<DatabaseEvent> messageStream(String chatId) {
    return _db.ref('chats/$chatId/messages').onValue;
  }

  // -------- SEND MESSAGE --------
  Future<void> sendMessage({
    required String toUid,
    required String text,
    required String toName,
  }) async {
    if (text.trim().isEmpty) return;

    final fromUser = _auth.currentUser;
    if (fromUser == null) return;

    final fromUid = fromUser.uid;
    final senderName = fromUser.displayName ?? "User"; // FIXED
    final receiverName = toName; // FIXED
    final now = DateTime.now().millisecondsSinceEpoch;

    final chatId = chatIdFor(fromUid, toUid);

    // 1️⃣ Add message
    await _db.ref('chats/$chatId/messages').push().set({
      'text': text.trim(),
      'fromUid': fromUid,
      'toUid': toUid,
      'timestamp': now,
      'senderName': senderName, // OPTIONAL
    });

    // 2️⃣ Update sender inbox
    await _db.ref('userChats/$fromUid/$chatId').set({
      'peerUid': toUid,
      'peerName': receiverName,
      'lastMessage': text.trim(),
      'lastTimestamp': now,
    });

    // 3️⃣ Update receiver inbox
    await _db.ref('userChats/$toUid/$chatId').set({
      'peerUid': fromUid,
      'peerName': senderName,
      'lastMessage': text.trim(),
      'lastTimestamp': now,
    });
  }
}
