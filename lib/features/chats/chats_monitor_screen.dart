import 'package:flutter/material.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../core/constants/app_colors.dart';

class ChatsMonitorScreen extends StatefulWidget {
  const ChatsMonitorScreen({Key? key}) : super(key: key);

  @override
  State<ChatsMonitorScreen> createState() => _ChatsMonitorScreenState();
}

class _ChatsMonitorScreenState extends State<ChatsMonitorScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  Color _getStatusColor(ChatStatus status) {
    switch (status) {
      case ChatStatus.requested: return Colors.yellow[700]!;
      case ChatStatus.chatting: return Colors.blue;
      case ChatStatus.agreed: return Colors.orange;
      case ChatStatus.contactVisible: return Colors.green;
      case ChatStatus.completed: return Colors.green[800]!;
      case ChatStatus.cancelled: return AppColors.danger;
      default: return Colors.grey;
    }
  }

  void _openChatDetails(ChatModel chat) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chat Details',
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: Container(
              width: 400,
              color: AppColors.surface,
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Chat Details'),
                    actions: [
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _firestoreService.streamChatMessages(chat.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) return const Center(child: Text('No messages'));

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isUser = msg.senderId == chat.userId;
                            return Align(
                              alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.background : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(msg.message),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<List<ChatModel>>(
          stream: _firestoreService.streamAllChats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

            final chats = snapshot.data ?? [];

            return CustomDataTable(
              columns: const [
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('Provider ID')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Created At')),
                DataColumn(label: Text('Actions')),
              ],
              rows: chats.map((c) {
                return DataRow(
                  cells: [
                    DataCell(Text(c.userId.substring(0, 8))),
                    DataCell(Text(c.providerId.substring(0, 8))), 
                    DataCell(
                      BadgeWidget(
                        text: c.status.name.toUpperCase(),
                        color: _getStatusColor(c.status),
                      )
                    ),
                    DataCell(Text(c.createdAt.toString())),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _openChatDetails(c),
                      ),
                    ),
                  ]
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

}
