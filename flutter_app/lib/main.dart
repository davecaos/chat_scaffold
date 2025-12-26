import 'package:flutter/material.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

const socketURL = String.fromEnvironment('SERVER_URL',
    defaultValue: 'ws://localhost:4000/socket/websocket');
const channelName =
    String.fromEnvironment('CHANNEL_NAME', defaultValue: 'chat:lobby');

void main() {
  runApp(const SimpleChatApp());
}

class SimpleChatApp extends StatelessWidget {
  const SimpleChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  PhoenixSocket? _socket;
  PhoenixChannel? _channel;
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  Future<void> _connectToServer() async {
    setState(() {
      _connectionStatus = 'Connecting...';
    });

    try {
      // Connect to Phoenix socket
      // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/web
      _socket = PhoenixSocket(
        socketURL,
        socketOptions: PhoenixSocketOptions(
          timeout: const Duration(seconds: 10),
        ),
      );

      // Listen to socket events
      _socket!.openStream.listen((_) {
        _joinChannel();
      });

      _socket!.closeStream.listen((event) {
        setState(() {
          _isConnected = false;
          _connectionStatus = 'Disconnected';
        });
      });

      _socket!.errorStream.listen((event) {
        setState(() {
          _connectionStatus = 'Error: ${event.error}';
        });
      });

      await _socket!.connect();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
      });
    }
  }

  void _joinChannel() async {
    if (_socket == null) return;

    _channel = _socket!.addChannel(topic: channelName);

    try {
      final response = await _channel!.join().future;
      if (response.isOk) {
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected';
        });

        // Listen for bot messages
        _channel!.messages.listen((message) {
          if (message.event.value == 'bot_message') {
            final payload = message.payload as Map<String, dynamic>?;
            if (payload != null && payload['text'] != null) {
              setState(() {
                _messages.add(ChatMessage(
                  text: payload['text'] as String,
                  isUser: false,
                ));
              });
              _scrollToBottom();
            }
          }
        });
      } else {
        setState(() {
          _connectionStatus = 'Failed to join channel';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Join failed: $e';
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _channel == null || !_isConnected) return;

    // Add user message to list
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _messageController.clear();
    _scrollToBottom();

    // Send to server
    try {
      await _channel!.push('new_message', {'text': text}).future;
    } catch (e) {
      // Handle error if needed
      debugPrint('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.leave();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: _isConnected ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _connectionStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.\nSend a message to start chatting!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: _isConnected,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isConnected ? _sendMessage : null,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }
}
