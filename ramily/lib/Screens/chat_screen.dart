import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'chat_detail_screen.dart';
import 'login_screen.dart';
import 'profile_editor.dart';
import 'constants.dart';

class ChatScreen extends StatefulWidget {
  final String email;
  
  const ChatScreen({Key? key, required this.email}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  
  // Tab controller for switching between chats and requests
  late TabController _tabController;
  
  // Counters for badges
  int _requestsCount = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserAuth();
    
    // Listen to tab changes
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Check if user is logged in
  Future<void> _checkUserAuth() async {
    setState(() => _isLoading = true);
    
    if (_auth.currentUser == null) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
  
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kDarkText,
            ),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: kDarkText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logOut(context);
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: kVCURed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
  
  void _openEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditorScreen(email: widget.email),
      ),
    );
  }
  
  // Format timestamp for display
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    
    final DateTime now = DateTime.now();
    final DateTime dateTime = timestamp.toDate();
    final Duration difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  // Method to delete a chat
  Future<void> _deleteChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Delete from user_chats collection
      await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('user_chats')
        .doc(chatId)
        .delete();
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation deleted'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Note: We don't delete the actual chat document or messages
      // to preserve the conversation for the other user
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting conversation: $e')),
      );
    }
  }

  // Method to delete a message request
  Future<void> _deleteMessageRequest(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Update chat status to declined
      await _firestore
        .collection('chats')
        .doc(chatId)
        .update({
          'status.${currentUser.uid}': 'declined',
        });
      
      // Delete from message_requests collection
      await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('message_requests')
        .doc(chatId)
        .delete();
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error deleting message request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting request: $e')),
      );
    }
  }
  
  // Handle request actions (accept/decline)
  Future<void> _handleRequestAction({
    required String chatId,
    required String otherUserId,
    required String action,
    String? otherUserName,
    String? lastMessage,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      if (action == 'accept') {
        // Update status in chat document
        await _firestore.collection('chats').doc(chatId).update({
          'status.${currentUser.uid}': 'accepted',
        });
        
        // Get the request data
        final requestDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('message_requests')
            .doc(chatId)
            .get();
        
        if (requestDoc.exists) {
          final requestData = requestDoc.data() as Map<String, dynamic>;
          
          // Add to user_chats collection
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('user_chats')
              .doc(chatId)
              .set({
            ...requestData,
            'status': 'accepted',
          });
          
          // Delete from message_requests
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('message_requests')
              .doc(chatId)
              .delete();
          
          // Navigate to chat
          if (otherUserName != null && lastMessage != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  name: otherUserName,
                  message: lastMessage,
                  chatId: chatId,
                  otherUserId: otherUserId,
                  status: 'accepted',
                ),
              ),
            );
          }
        }
      } else if (action == 'decline') {
        // Update status in chat document
        await _firestore.collection('chats').doc(chatId).update({
          'status.${currentUser.uid}': 'declined',
        });
        
        // Delete from message_requests
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('message_requests')
            .doc(chatId)
            .delete();
            // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message request declined'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error handling request action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) 
            : Column(
                children: [
                  // Header with title and actions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chats',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: kDarkText,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search, color: kDarkText),
                              onPressed: () {},
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.settings_outlined, color: kDarkText),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              offset: const Offset(0, 40),
                              onSelected: (value) {
                                if (value == 'edit_profile') {
                                  _openEditor(context);
                                } else if (value == 'logout') {
                                  _showSignOutDialog(context);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'edit_profile',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, color: kPrimaryColor, size: 20),
                                      const SizedBox(width: 12),
                                      const Text('Edit Profile'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.logout, color: kVCURed, size: 20),
                                      const SizedBox(width: 12),
                                      const Text('Log Out'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab bar for chats and requests
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: kVCUGold,
                      labelColor: kDarkText,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      tabs: [
                        const Tab(text: 'Chats'),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Requests'),
                              // Show badge if there are requests
                              StreamBuilder<QuerySnapshot>(
                                stream: currentUser != null
                                    ? _firestore
                                        .collection('users')
                                        .doc(currentUser.uid)
                                        .collection('message_requests')
                                        .snapshots()
                                    : null,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                    _requestsCount = snapshot.data!.docs.length;
                                    return Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: kVCURed,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _requestsCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  _requestsCount = 0;
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab views for chats and requests
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ACTIVE CHATS TAB
                        StreamBuilder<QuerySnapshot>(
                          stream: currentUser != null
                              ? _firestore
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .collection('user_chats')
                                  .orderBy('updatedAt', descending: true)
                                  .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return _buildEmptyState();
                            }
                            
                            final chatDocs = snapshot.data!.docs;
                            
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: chatDocs.length,
                              itemBuilder: (context, index) {
                                final chatData = chatDocs[index].data() as Map<String, dynamic>;
                                
                                final String otherUserName = chatData['otherUserName'] ?? 'VCU Student';
                                final String lastMessage = chatData['lastMessage'] ?? '';
                                final Timestamp? lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
                                final int unreadCount = (chatData['unreadCount'] as num?)?.toInt() ?? 0;
                                final String chatId = chatData['chatId'] ?? '';
                                final String otherUserId = chatData['otherUserId'] ?? '';
                                final String status = chatData['status'] ?? 'accepted';
                                
                                // Get first letter for avatar
                                final String firstLetter = otherUserName.isNotEmpty
                                    ? otherUserName[0].toUpperCase()
                                    : 'V';
                                
                                // Use Dismissible for swipe-to-delete functionality
                                return Dismissible(
                                  key: Key(chatId),
                                  background: Container(
                                    color: kVCURed,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    alignment: Alignment.centerRight,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.delete, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    // Show confirmation dialog
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete Conversation'),
                                          content: Text('Are you sure you want to delete your conversation with $otherUserName?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(color: kVCURed),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) {
                                    // Delete the chat from user_chats collection
                                    _deleteChat(chatId);
                                  },
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatDetailScreen(
                                            name: otherUserName,
                                            message: lastMessage,
                                            chatId: chatId,
                                            otherUserId: otherUserId,
                                            status: status,
                                          ),
                                        ),
                                      );
                                    },
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: kVCUGold,
                                          child: Text(
                                            firstLetter,
                                            style: const TextStyle(
                                              color: kVCUBlack,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: kVCURed,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: unreadCount > 1
                                                  ? Center(
                                                      child: Text(
                                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      otherUserName,
                                      style: TextStyle(
                                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                        color: kDarkText,
                                      ),
                                    ),
                                    subtitle: Text(
                                      lastMessage,
                                      style: TextStyle(
                                        color: unreadCount > 0 ? kVCUBlue : Colors.grey,
                                        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      _formatTimestamp(lastMessageTime),
                                      style: TextStyle(
                                        color: unreadCount > 0 ? kVCUGold : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        
                        // MESSAGE REQUESTS TAB
                        StreamBuilder<QuerySnapshot>(
                          stream: currentUser != null
                              ? _firestore
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .collection('message_requests')
                                  .orderBy('updatedAt', descending: true)
                                  .snapshots()
                              : null,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return _buildEmptyRequestsState();
                            }
                            
                            final requestDocs = snapshot.data!.docs;
                            
                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: requestDocs.length,
                              itemBuilder: (context, index) {
                                final requestData = requestDocs[index].data() as Map<String, dynamic>;
                                
                                final String otherUserName = requestData['otherUserName'] ?? 'VCU Student';
                                final String lastMessage = requestData['lastMessage'] ?? '';
                                final Timestamp? lastMessageTime = requestData['lastMessageTime'] as Timestamp?;
                                final int unreadCount = (requestData['unreadCount'] as num?)?.toInt() ?? 0;
                                final String chatId = requestData['chatId'] ?? '';
                                final String otherUserId = requestData['otherUserId'] ?? '';
                                final String status = requestData['status'] ?? 'pending';
                                
                                // Get first letter for avatar
                                final String firstLetter = otherUserName.isNotEmpty
                                    ? otherUserName[0].toUpperCase()
                                    : 'V';
                                
                                // Use Dismissible for swipe-to-delete functionality
                                return Dismissible(
                                  key: Key(chatId),
                                  background: Container(
                                    color: kVCURed,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    alignment: Alignment.centerRight,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.delete, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    // Show confirmation dialog
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete Request'),
                                          content: Text('Delete message request from $otherUserName?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(color: kVCURed),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) {
                                    // Delete the request
                                    _deleteMessageRequest(chatId);
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          // User info
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: kVCUGold,
                                                child: Text(
                                                  firstLetter,
                                                  style: const TextStyle(
                                                    color: kVCUBlack,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      otherUserName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        color: kDarkText,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Wants to connect with you',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                _formatTimestamp(lastMessageTime),
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 12),
                                          
                                          // Message preview
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.chat_bubble_outline,
                                                  size: 16,
                                                  color: kVCUBlue,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    lastMessage,
                                                    style: const TextStyle(
                                                      color: kDarkText,
                                                      fontSize: 14,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          const SizedBox(height: 12),
                                          
                                          // Action buttons
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () => _handleRequestAction(
                                                    chatId: chatId,
                                                    otherUserId: otherUserId,
                                                    action: 'decline',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(color: Colors.grey[400]!),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: const Text('Decline'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () => _handleRequestAction(
                                                    chatId: chatId,
                                                    otherUserId: otherUserId,
                                                    action: 'accept',
                                                    otherUserName: otherUserName,
                                                    lastMessage: lastMessage,
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: kVCUGold,
                                                    foregroundColor: kVCUBlack,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Accept',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 4),
                                          
                                          // View request button
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ChatDetailScreen(
                                                    name: otherUserName,
                                                    message: lastMessage,
                                                    chatId: chatId,
                                                    otherUserId: otherUserId,
                                                    status: status,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View Request',
                                              style: TextStyle(
                                                color: kVCUBlue,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  // Empty state when no chats exist
  Widget _buildEmptyState() {
  return Column(
    children: [
      // Default chat with Rodney Ram - improved formatting
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  name: 'Rodney Ram',
                  message: 'Welcome to VCU!',
                  chatId: 'welcome_${_auth.currentUser?.uid ?? 'guest'}',
                  otherUserId: 'rodney_ram',
                  status: 'accepted',
                ),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: kVCUGold.withOpacity(0.15),
                child: const Text(
                  'R',
                  style: TextStyle(
                    color: kAccentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: const Text(
            'Rodney Ram',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kDarkText,
            ),
          ),
          subtitle: const Text(
            'Welcome to VCU!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Text(
            'Just now',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
      
      const Divider(height: 32),
      
      // Empty state information with proper spacing
      Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with students to start chatting',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to the main screen and then to the matching screen
                  Navigator.pop(context, 'goto_matching');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kVCUGold,
                  foregroundColor: kVCUBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Find Matches',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
  
  // Empty state for message requests
  Widget _buildEmptyRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No message requests',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone new messages you,\nit will appear here for approval',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}