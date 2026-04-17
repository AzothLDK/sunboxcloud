import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class AssistantTab extends StatefulWidget {
  const AssistantTab({super.key});

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 加载本地存储的消息
  Future<void> _loadMessages() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? messagesJson = prefs.getString('assistant_messages');
      if (messagesJson != null) {
        List<dynamic> messagesList = jsonDecode(messagesJson);
        setState(() {
          _messages = messagesList.map((msg) => Message.fromJson(msg)).toList();
        });
      }
    } catch (e) {
      print('加载消息失败: $e');
    }
  }

  // 保存消息到本地存储
  Future<void> _saveMessages() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> messagesJson = _messages
          .map((msg) => msg.toJson())
          .toList();
      await prefs.setString('assistant_messages', jsonEncode(messagesJson));
    } catch (e) {
      print('保存消息失败: $e');
    }
  }

  // 发送消息
  void _sendMessage() {
    String text = _textController.text.trim();
    if (text.isEmpty) return;

    // 添加用户消息
    setState(() {
      _messages.add(
        Message(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _textController.clear();
      _isLoading = true;
    });

    // 保存消息
    _saveMessages();

    // 模拟 AI 回复
    Future.delayed(const Duration(seconds: 1), () {
      String reply = _getAIReply(text);
      setState(() {
        _messages.add(
          Message(text: reply, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
      // 保存消息
      _saveMessages();
      // 滚动到底部
      _scrollToBottom();
    });

    // 滚动到底部
    _scrollToBottom();
  }

  // 模拟 AI 回复
  String _getAIReply(String userInput) {
    // 简单的模拟回复逻辑
    userInput = userInput.toLowerCase();
    if (userInput.contains('你好') ||
        userInput.contains('hello') ||
        userInput.contains('hi')) {
      return '你好！我是你的智能助手，有什么可以帮助你的吗？';
    } else if (userInput.contains('天气') || userInput.contains('weather')) {
      return '今天天气晴朗，温度适宜，是个好天气！';
    } else if (userInput.contains('能源') || userInput.contains('energy')) {
      return '我们的系统可以帮助你监控和管理能源使用，优化能源消耗，降低能源成本。';
    } else if (userInput.contains('电池') || userInput.contains('battery')) {
      return '电池状态良好，当前SOC为20%，建议保持在20%-80%之间以延长电池寿命。';
    } else if (userInput.contains('帮助') || userInput.contains('help')) {
      return '我可以帮助你了解系统状态、能源使用情况、电池状态等信息。你可以问我关于天气、能源管理、电池状态等问题。';
    } else {
      return '感谢你的提问！我正在学习中，会不断提高我的回答能力。如果你有关于能源管理或系统状态的问题，我很乐意帮助你。';
    }
  }

  // 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // 清空聊天记录
  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('clear_chat_history'.tr),
          content: Text('confirm_clear_chat'.tr),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: () async {
                // 清空消息列表
                setState(() {
                  _messages = [];
                });
                // 清空本地存储
                try {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('assistant_messages');
                } catch (e) {
                  print('清空消息失败: $e');
                }
                Navigator.of(context).pop();
              },
              child: Text('clear'.tr),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('ai_assistant'.tr),
        // backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChatHistory,
            tooltip: 'clear_chat_history'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          // 对话区域
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                Message message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: message.isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isUser)
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message.isUser ? primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: message.isUser ? Colors.white : textColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (message.isUser)
                        Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300]!,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 输入区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'enter_message'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 消息模型
class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // 从 JSON 转换
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
