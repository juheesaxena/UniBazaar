import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatService {
  // ---------- SINGLETON ----------
  ChatService._internal();
  static final ChatService instance = ChatService._internal();
  factory ChatService() => instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late FirebaseDatabase _db;

  bool _initialized = false;

  // ---------- MUST BE CALLED ONCE ----------
  void init() {
    if (_initialized) return;

    final FirebaseApp app = Firebase.app();
    _db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          "https://unibazaar-73dd2-default-rtdb.asia-southeast1.firebasedatabase.app",
    );

    _initialized = true;
    print("🔥 ChatService Initialized");
  }

  // ---------- STABLE CHAT ID ----------
  String chatIdFor(String uid1, String uid2) {
    return uid1.hashCode < uid2.hashCode ? "${uid1}_$uid2" : "${uid2}_$uid1";
  }

  // ---------- GET MESSAGE STREAM ----------
  Stream<DatabaseEvent> messageStream(String chatId) {
    return _db.ref("chats/$chatId").onValue;
  }

  // ---------- SEND MESSAGE ----------
  Future<void> sendMessage({
    required String toUid,
    required String text,
    required String toName,
  }) async {
    if (!_initialized) init();

    final fromUid = _auth.currentUser!.uid;
    final fromName = _auth.currentUser!.displayName ?? "User";
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final chatId = chatIdFor(fromUid, toUid);
    final msgRef = _db.ref("chats/$chatId").push();

    // store message
    await msgRef.set({
      "fromUid": fromUid,
      "toUid": toUid,
      "text": text,
      "timestamp": timestamp,
    });

    // sender inbox
    await _db.ref("userChats/$fromUid/$chatId").update({
      "uid": toUid,
      "name": toName,
      "lastMessage": text,
      "timestamp": timestamp,
      "unread": 0,
    });

    // receiver inbox
    await _db.ref("userChats/$toUid/$chatId").update({
      "uid": fromUid,
      "name": fromName,
      "lastMessage": text,
      "timestamp": timestamp,
      "unread": ServerValue.increment(1),
    });
  }

  // ---------- UNREAD COUNTER ----------
  Stream<int> getUnreadMessageCount(String uid) {
    return _db.ref("userChats/$uid").onValue.map((event) {
      if (event.snapshot.value == null) return 0;

      final chats = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      int count = 0;

      chats.forEach((key, chat) {
        if (chat is Map && chat["unread"] != null) {
          count += (chat["unread"] as num).toInt();
        }
      });

      return count;
    });
  }

  // ---------- MARK CHAT AS READ ----------
  Future<void> markChatAsRead(String chatId) async {
    final uid = _auth.currentUser!.uid;
    await _db.ref("userChats/$uid/$chatId/unread").set(0);
  }
}
