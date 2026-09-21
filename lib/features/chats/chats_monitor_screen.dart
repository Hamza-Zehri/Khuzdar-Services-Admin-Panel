import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/models/all_models.dart';
import '../../core/services/admin_firestore_service.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../shared/widgets/status_display.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_colors.dart';

class ChatsMonitorScreen extends StatefulWidget {
  const ChatsMonitorScreen({super.key});

  @override
  State<ChatsMonitorScreen> createState() => _ChatsMonitorScreenState();
}

class _ChatsMonitorScreenState extends State<ChatsMonitorScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  ChatStatus? _statusFilter;

  Color _getStatusColor(ChatStatus status) {
    switch (status) {
      case ChatStatus.requested:
        return Colors.amber.shade700;
      case ChatStatus.chatting:
        return AppColors.info;
      case ChatStatus.agreed:
        return Colors.orange.shade700;
      case ChatStatus.contactVisible:
        return AppColors.success;
      case ChatStatus.completed:
        return Colors.green.shade800;
      case ChatStatus.cancelled:
        return AppColors.danger;
    }
  }

  void _openChatDetails(ChatModel chat) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chat Details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppColors.surface,
            elevation: 16,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 400,
              height: MediaQuery.of(context).size.height * 0.92,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceAlt,
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chat Details',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<MessageModel>>(
                      stream: _firestoreService.streamChatMessages(chat.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return StatusDisplay.loading();
                        }
                        if (snapshot.hasError) {
                          return StatusDisplay.error(detail: '${snapshot.error}');
                        }

                        final messages = snapshot.data ?? [];
                        if (messages.isEmpty) {
                          return StatusDisplay.empty(message: 'No messages yet');
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isUser = msg.senderId == chat.userId;
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                constraints: const BoxConstraints(maxWidth: 280),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.surfaceAlt
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: isUser
                                        ? AppColors.border
                                        : AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.message,
                                      style: const TextStyle(fontSize: 13.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatDate(msg.timestamp),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textMuted,
                                      ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Chats Monitor',
              subtitle: 'Overview of active customer–provider conversations',
            ),
            const SizedBox(height: 16),
            // Status filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, 'All'),
                  for (final status in ChatStatus.values)
                    _filterChip(status, capitalize(status.name)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: _firestoreService.streamAllChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return StatusDisplay.loading();
                  }
                  if (snapshot.hasError) {
                    return StatusDisplay.error(detail: '${snapshot.error}');
                  }

                  var chats = snapshot.data ?? [];
                  if (_statusFilter != null) {
                    chats = chats
                        .where((c) => c.status == _statusFilter)
                        .toList();
                  }

                  if (chats.isEmpty) {
                    return StatusDisplay.empty(
                      message: _statusFilter != null
                          ? 'No chats with this status'
                          : 'No chats yet',
                      detail: 'New conversations will appear here automatically',
                    );
                  }

                  return CustomDataTable(
                    minWidth: 640,
                    columns: const [
                      DataColumn2(label: Text('User ID'), size: ColumnSize.M),
                      DataColumn2(label: Text('Provider ID'), size: ColumnSize.M),
                      DataColumn2(label: Text('Last Message'), size: ColumnSize.L),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(label: Text('Created'), size: ColumnSize.M),
                      DataColumn2(label: Text('Actions'), fixedWidth: 80),
                    ],
                    rows: chats.map((c) {
                      return DataRow(
                        cells: [
                          DataCell(Text(shortId(c.userId), style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(shortId(c.providerId))),
                          DataCell(
                            Text(
                              c.lastMessage ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            BadgeWidget(
                              text: c.status.name.toUpperCase(),
                              color: _getStatusColor(c.status),
                            ),
                          ),
                          DataCell(Text(formatDate(c.createdAt))),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              tooltip: 'View conversation',
                              onPressed: () => _openChatDetails(c),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(ChatStatus? status, String label) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = status),
        showCheckmark: false,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}