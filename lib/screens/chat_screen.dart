import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme.dart';
import '../database/db_helper.dart';
import '../services/gemini_service.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final VoidCallback onBack;
  const ChatScreen({super.key, required this.chatId, required this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  String _chatTitle = "MonIA";

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Load history from DB
    final msgs = await DbHelper.instance.readMessagesForChat(widget.chatId);
    
    // Load Chat Title
    final chats = await DbHelper.instance.readAllChats();
    final currentChat = chats.firstWhere((c) => c['id'] == widget.chatId, orElse: () => {'title': 'MonIA'});
    
    setState(() {
      _messages = List<Map<String, dynamic>>.from(msgs);
      _chatTitle = currentChat['subtitle'] ?? currentChat['title'] ?? 'MonIA';
      _isLoading = false;
    });

    // 2. Initialize Gemini with context
    try {
      await GeminiService().startChatSession(widget.chatId, _messages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar IA: $e'), backgroundColor: Colors.red),
        );
      }
    }

    // 3. If empty, add a welcome message locally
    if (_messages.isEmpty) {
      final welcome = {
        'chatId': widget.chatId,
        'text': '¡Hola! Soy MonIA, tu asistente financiero IA. Analizaré tus cuentas y saldos en tiempo real. ¿En qué te puedo ayudar hoy?',
        'isUser': 0,
        'time': _formatTime(DateTime.now()),
      };
      await DbHelper.instance.createMessage(welcome);
      setState(() {
        _messages.add(welcome);
      });
    }
  }

  String _formatTime(DateTime time) {
    String min = time.minute.toString().padLeft(2, '0');
    return '${time.hour}:$min';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userText = _messageController.text.trim();
    _messageController.clear();
    
    final userMsg = {
      'chatId': widget.chatId,
      'text': userText,
      'isUser': 1,
      'time': _formatTime(DateTime.now()),
    };
    
    // Save user message to DB
    await DbHelper.instance.createMessage(userMsg);
    await DbHelper.instance.updateChatSubtitle(widget.chatId, userText);
    
    setState(() {
      _messages.add(userMsg);
      _chatTitle = userText;
      _isTyping = true;
    });

    // Create empty bot message
    final botMsg = {
      'chatId': widget.chatId,
      'text': '',
      'isUser': 0,
      'time': _formatTime(DateTime.now()),
    };
    
    setState(() {
      _messages.add(botMsg);
    });

    // Get Gemini response stream
    final stream = GeminiService().sendMessageStream(userText);
    String fullResponse = '';

    try {
      await for (final chunk in stream) {
        if (mounted) {
          setState(() {
            _isTyping = false;
            fullResponse += chunk;
            _messages.last['text'] = fullResponse;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          fullResponse = "Error interno: $e";
          _messages.last['text'] = fullResponse;
        });
      }
    }
    
    if (mounted) {
      botMsg['text'] = fullResponse;
      await DbHelper.instance.createMessage(botMsg);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: widget.onBack,
        ),
        title: Text(
          _chatTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['isUser'] == 1;
                    
                    return _buildMessageBubble(
                      text: message['text'] as String,
                      time: message['time'] as String,
                      isUser: isUser,
                    );
                  },
                ),
          ),
          
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('MonIA está escribiendo...', style: TextStyle(color: AppTheme.accentGreen, fontSize: 12)),
              ),
            ),
          
          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required String time, required bool isUser}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1E2024) : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: isUser ? Border.all(color: Colors.white10) : null,
                  ),
                  child: MarkdownBody(
                    data: text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      strong: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      em: const TextStyle(
                        color: AppTheme.accentGreen,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 40,
              right: isUser ? 40 : 0,
            ),
            child: Text(
              time,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark, // Match background to web
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark, // Dark grey background
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: AppTheme.textSecondary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
