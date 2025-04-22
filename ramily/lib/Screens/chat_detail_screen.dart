import 'package:flutter/material.dart';
// Import for color constants
import 'constants.dart'; 


class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String message;

  const ChatDetailScreen({
    super.key, 
    required this.name, 
    required this.message,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  
  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    _messages.add({
      'isMe': false,
      'message': 'Welcome to VCU!',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'isMe': true,
          'message': _messageController.text.trim(),
          'time': DateTime.now(),
        });
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDarkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.name,
          style: const TextStyle(
            color: kDarkText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message['isMe'] 
                      ? Alignment.centerRight 
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: 12,
                      left: message['isMe'] ? 50 : 0,
                      right: message['isMe'] ? 0 : 50,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: message['isMe'] 
                          ? kVCUBlue 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(
                        color: message['isMe'] ? Colors.white : kDarkText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type something to send...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: kPrimaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}