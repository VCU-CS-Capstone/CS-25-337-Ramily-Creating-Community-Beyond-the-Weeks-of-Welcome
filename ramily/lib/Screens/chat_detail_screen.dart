import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String message;
  final String chatId;
  final String otherUserId;
  final String status;

  const ChatDetailScreen({
    Key? key, 
    required this.name, 
    required this.message,
    required this.chatId,
    required this.otherUserId,
    required this.status,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  String _chatStatus = 'pending'; // Default to pending
  
  @override
  void initState() {
    super.initState();
    _chatStatus = widget.status;
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Mark messages as read when opening the chat
  Future<void> _markMessagesAsRead() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Only mark as read if the chat is accepted
      if (_chatStatus != 'accepted') return;

      // Get the chat document
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      
      // Update unread count for current user to 0
      await chatRef.update({
        'unreadCount.${currentUser.uid}': 0
      });

      // Also update the user_chats collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_chats')
          .doc(widget.chatId)
          .update({
        'unreadCount': 0
      });

      // Mark all messages as read
      final batch = FirebaseFirestore.instance.batch();
      
      final unreadMessages = await chatRef
          .collection('messages')
          .where('senderId', isEqualTo: widget.otherUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Send a new message
  void _sendMessage() async {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    
    _messageController.clear();

    try {
      setState(() {
        _isLoading = true;
      });
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Get current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!currentUserDoc.exists) return;
      
      final userData = currentUserDoc.data() as Map<String, dynamic>;
      final senderName = userData['name'] ?? 'VCU Student';

      final timestamp = FieldValue.serverTimestamp();
      
      // Add message to the messages collection
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        'senderName': senderName,
        'text': messageText,
        'timestamp': timestamp,
        'isRead': false,
      });

      // Update the chat document with the latest message info
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'lastMessageSender': currentUser.uid,
        // Increment unread count for the other user
        'unreadCount.${widget.otherUserId}': FieldValue.increment(1),
      });

      // Update both users' chat lists
      // For current user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('user_chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'updatedAt': timestamp,
      });

      // For other user - check if chat is in user_chats or message_requests
      final otherUserChatDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .collection('user_chats')
          .doc(widget.chatId)
          .get();
          
      if (otherUserChatDoc.exists) {
        // Update in user_chats
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.otherUserId)
            .collection('user_chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': messageText,
          'lastMessageTime': timestamp,
          'unreadCount': FieldValue.increment(1),
          'updatedAt': timestamp,
        });
      } else {
        // Check if it's in message_requests
        final otherUserRequestDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.otherUserId)
            .collection('message_requests')
            .doc(widget.chatId)
            .get();
            
        if (otherUserRequestDoc.exists) {
          // Update in message_requests
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUserId)
              .collection('message_requests')
              .doc(widget.chatId)
              .update({
            'lastMessage': messageText,
            'lastMessageTime': timestamp,
            'unreadCount': FieldValue.increment(1),
            'updatedAt': timestamp,
          });
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add methods to handle request actions
  Future<void> _acceptRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update status to accepted in the chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'status.${currentUser.uid}': 'accepted',
      });

      // Move from message_requests to user_chats for current user
      final requestDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('message_requests')
          .doc(widget.chatId)
          .get();

      if (requestDoc.exists) {
        final requestData = requestDoc.data() as Map<String, dynamic>;
        
        // Create entry in user_chats
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('user_chats')
            .doc(widget.chatId)
            .set({
          ...requestData,
          'status': 'accepted',
        });

        // Delete from message_requests
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('message_requests')
            .doc(widget.chatId)
            .delete();
      }

      setState(() {
        _chatStatus = 'accepted';
        _isLoading = false;
      });
      
      // Mark messages as read now that chat is accepted
      _markMessagesAsRead();
    } catch (e) {
      print('Error accepting request: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request: $e')),
      );
    }
  }

  Future<void> _declineRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update status to declined in the chat document
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'status.${currentUser.uid}': 'declined',
      });

      // Delete from message_requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('message_requests')
          .doc(widget.chatId)
          .delete();

      setState(() {
        _isLoading = false;
      });

      // Navigate back after declining
      Navigator.pop(context);
    } catch (e) {
      print('Error declining request: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline request: $e')),
      );
    }
  }
  
  // Report dialog method
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Report User', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kVCURed,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why are you reporting this user?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildReportOption('Inappropriate messages'),
              _buildReportOption('Spam or scam'),
              _buildReportOption('Harassment or bullying'),
              _buildReportOption('Fake profile'),
              _buildReportOption('Other'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Show confirmation message
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted. Our team will review it shortly.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kVCURed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        );
      },
    );
  }

  // Helper for report options
  Widget _buildReportOption(String text) {
    return InkWell(
      onTap: () {
        // In a real implementation, this would store the selected reason
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const Icon(Icons.radio_button_unchecked, size: 20),
            const SizedBox(width: 12),
            Text(text),
          ],
        ),
      ),
    );
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
        // Add actions menu with Report option
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kDarkText),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem, color: kVCURed, size: 20),
                    SizedBox(width: 8),
                    Text('Report User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Display message request banner if status is pending
          if (_chatStatus == 'pending') 
            _buildMessageRequestBanner(),
          
          // Messages area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final messages = snapshot.data!.docs;
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  return const Center(child: Text('Not logged in'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true, // Display newest messages at the bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == currentUser.uid;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 12,
                          left: isMe ? 50 : 0,
                          right: isMe ? 0 : 50,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, 
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? kVCUBlue : Colors.grey[200],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : kDarkText,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message['timestamp'] != null
                                      ? _formatTimestamp(message['timestamp'] as Timestamp)
                                      : 'Just now',
                                  style: TextStyle(
                                    color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message['isRead'] == true 
                                        ? Icons.done_all 
                                        : Icons.done,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input area - Show only if request is accepted
          if (_chatStatus == 'accepted')
            _buildMessageInputArea(),
        ],
      ),
    );
  }

  // Message request banner widget
  Widget _buildMessageRequestBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kVCUGold.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.notification_important,
                color: kVCUGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Message Request',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kDarkText,
                      ),
                    ),
                    Text(
                      '${widget.name} wants to start a conversation with you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Decline button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _declineRequest,
                  icon: const Icon(Icons.close, color: kVCURed),
                  label: const Text(
                    'Decline',
                    style: TextStyle(color: kVCURed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kVCURed),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Accept button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _acceptRequest,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kVCUGreen,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Message input area widget
  Widget _buildMessageInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
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
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: kPrimaryColor),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }
  
  // Format Firestore timestamps into readable time
  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) {
      return '${date.month}/${date.day}/${date.year}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}