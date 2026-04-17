import 'package:flutter/material.dart';
import '../../core/services/fcm_broadcast_service.dart';
import '../../shared/widgets/badge_widget.dart';
import '../../shared/widgets/data_table_widget.dart';
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast logged successfully', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Section
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Send Notification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bodyController,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        RadioGroup<String>(
                          groupValue: _selectedTarget,
                          onChanged: (v) => setState(() => _selectedTarget = v.toString()),
                          child: Column(
                            children: [
                              RadioListTile(
                                title: const Text('All Users'),
                                value: 'all_users',
                              ),
                              RadioListTile(
                                title: const Text('All Clients (Customers Only)'),
                                value: 'all_clients',
                              ),
                              RadioListTile(
                                title: const Text('All Providers'),
                                value: 'all_providers',
                              ),
                              RadioListTile(
                                title: const Text('Approved Providers Only'),
                                value: 'approved_providers',
                              ),
                              RadioListTile(
                                title: const Text('Specific User (UID)'),
                                value: 'specific',
                              ),
                            ],
                          ),
                        ),
                        if (_selectedTarget == 'specific') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _uidController,
                            decoration: const InputDecoration(labelText: 'User or Provider UID', border: OutlineInputBorder()),
                            validator: (v) => _selectedTarget == 'specific' && v!.isEmpty ? 'Required' : null,
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text('Delivery Method', style: TextStyle(fontWeight: FontWeight.bold)),
                        RadioGroup<String>(
                          groupValue: _selectedMethod,
                          onChanged: (v) => setState(() => _selectedMethod = v.toString()),
                          child: Column(
                            children: [
                              RadioListTile(
                                title: const Text('Push Notification Only'),
                                value: 'notification',
                              ),
                              RadioListTile(
                                title: const Text('In-App Message Only'),
                                value: 'in_app',
                              ),
                              RadioListTile(
                                title: const Text('Both (Recommended)'),
                                value: 'both',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                            onPressed: _isLoading ? null : _sendBroadcast,
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Broadcast'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // History Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, right: 24.0, bottom: 24.0),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Broadcast History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _fcmService.streamBroadcastHistory(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                          final history = snapshot.data ?? [];

                          return CustomDataTable(
                            showBottomBorder: false,
                            columns: const [
                              DataColumn(label: Text('Timestamp')),
                              DataColumn(label: Text('Title')),
                              DataColumn(label: Text('Target')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: history.map((h) {
                              // Using try-catch or safe type check for timestamp in a real app
                              final String ts = h['createdAt'] != null ? h['createdAt'].toDate().toString() : 'Sending...';
                              return DataRow(
                                cells: [
                                  DataCell(Text(ts)),
                                  DataCell(Text(h['title'] ?? '')),
                                  DataCell(Text(h['target'] ?? '')),
                                  DataCell(
                                    BadgeWidget(
                                      text: h['status'] ?? 'unknown',
                                      color: h['status'] == 'completed' ? Colors.green : AppColors.accent,
                                    )
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                      onPressed: () async {
                                        await _fcmService.deleteBroadcast(h['id']);
                                      },
                                    )
                                  ),
                                ]
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
