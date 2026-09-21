import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/services/fcm_broadcast_service.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../shared/widgets/data_table_widget.dart';
import '../../shared/widgets/status_display.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_colors.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final FcmBroadcastService _fcmService = FcmBroadcastService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _uidController = TextEditingController();

  String _selectedTarget = 'all_users';
  String _selectedMethod = 'both';

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _fcmService.sendBroadcast(
          title: _titleController.text,
          body: _bodyController.text,
          target: _selectedTarget,
          method: _selectedMethod,
          specificUid: _selectedTarget == 'specific' ? _uidController.text : null,
        );
        _titleController.clear();
        _bodyController.clear();
        _uidController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Broadcast sent successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          final formSection = _buildFormSection();
          final historySection = _buildHistorySection();

          if (!isWide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  formSection,
                  const SizedBox(height: 24),
                  historySection,
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: formSection),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: historySection),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Broadcast',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Send push notifications and in-app messages',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message Body'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Message is required' : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Audience',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            RadioGroup<String>(
              groupValue: _selectedTarget,
              onChanged: (v) => setState(() => _selectedTarget = v.toString()),
              child: Column(
                children: [
                  _RadioTile(value: 'all_users', title: 'All Users'),
                  _RadioTile(value: 'all_clients', title: 'All Clients (Customers Only)'),
                  _RadioTile(value: 'all_providers', title: 'All Providers'),
                  _RadioTile(value: 'approved_providers', title: 'Approved Providers Only'),
                  _RadioTile(value: 'specific', title: 'Specific User (UID)'),
                ],
              ),
            ),
            if (_selectedTarget == 'specific') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _uidController,
                decoration: const InputDecoration(labelText: 'User or Provider UID'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'UID is required for this target' : null,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Delivery Method',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            RadioGroup<String>(
              groupValue: _selectedMethod,
              onChanged: (v) => setState(() => _selectedMethod = v.toString()),
              child: Column(
                children: [
                  _RadioTile(value: 'notification', title: 'Push Notification Only'),
                  _RadioTile(value: 'in_app', title: 'In-App Message Only'),
                  _RadioTile(value: 'both', title: 'Both (Recommended)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendBroadcast,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Broadcast'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Broadcast History',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fcmService.streamBroadcastHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return StatusDisplay.loading();
                }
                if (snapshot.hasError) {
                  return StatusDisplay.error(detail: '${snapshot.error}');
                }

                final history = snapshot.data ?? [];

                if (history.isEmpty) {
                  return StatusDisplay.empty(
                    message: 'No broadcasts yet',
                    detail: 'Sent broadcasts will be listed here',
                  );
                }

                return CustomDataTable(
                  showBottomBorder: true,
                  columns: const [
                    DataColumn2(label: Text('Timestamp'), size: ColumnSize.L),
                    DataColumn2(label: Text('Title'), size: ColumnSize.L),
                    DataColumn2(label: Text('Target'), size: ColumnSize.M),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    DataColumn2(label: Text('Actions'), fixedWidth: 80),
                  ],
                  rows: history.map((h) {
                    final ts = h['createdAt'] != null
                        ? formatDate((h['createdAt'] as Timestamp).toDate())
                        : 'Sending…';
                    final status = (h['status'] ?? 'unknown').toString();
                    return DataRow(
                      cells: [
                        DataCell(Text(ts)),
                        DataCell(Text(h['title']?.toString() ?? '')),
                        DataCell(Text(h['target']?.toString() ?? '')),
                        DataCell(
                          BadgeWidget(
                            text: capitalize(status),
                            color: status == 'completed'
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger),
                            tooltip: 'Delete broadcast',
                            onPressed: () async {
                              await _fcmService.deleteBroadcast(h['id']);
                            },
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
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String value;
  final String title;

  const _RadioTile({required this.value, required this.title});

  @override
  Widget build(BuildContext context) {
    return RadioListTile(
      value: value,
      title: Text(
        title,
        style: const TextStyle(fontSize: 13.5),
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }
}