import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool showEmojiPicker = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (text.isEmpty || user == null) return;

    // Obține numele din colecția 'users'
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Anonim';

    await FirebaseFirestore.instance.collection('chat_messages').add({
      'text': text,
      'userId': user.uid,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
    setState(() => showEmojiPicker = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final text = data['text'] ?? '';
                    final userName = data['userName'] ?? 'Anonim';
                    return ListTile(
                      title: Text(userName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(text),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: () => setState(() => showEmojiPicker = !showEmojiPicker),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Scrie un mesaj...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
          if (showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _controller.text += emoji.emoji;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _controller.text.length),
                  );
                },
                config: const Config(
                  columns: 7,
                  emojiSizeMax: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
