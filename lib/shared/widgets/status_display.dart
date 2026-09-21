import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum StatusKind { loading, empty, error }

/// Consistent loading / empty / error state for screens backed by streams.
class StatusDisplay extends StatelessWidget {
  final StatusKind kind;
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  const StatusDisplay({
    super.key,
    required this.kind,
    this.message = '',
    this.detail,
    this.onRetry,
  });

  factory StatusDisplay.loading({String message = 'Loading…'}) {
    return StatusDisplay(kind: StatusKind.loading, message: message);
  }

  factory StatusDisplay.empty({
    String message = 'Nothing here yet',
    String? detail,
    VoidCallback? onRetry,
  }) {
    return StatusDisplay(
      kind: StatusKind.empty,
      message: message,
      detail: detail,
      onRetry: onRetry,
    );
  }

  factory StatusDisplay.error({
    String message = 'Something went wrong',
    String? detail,
    VoidCallback? onRetry,
  }) {
    return StatusDisplay(kind: StatusKind.error, message: message, detail: detail, onRetry: onRetry);
  }

  @override
  Widget build(BuildContext context) {
    final Color color = switch (kind) {
      StatusKind.error => AppColors.danger,
      StatusKind.empty => AppColors.textSecondary,
      StatusKind.loading => AppColors.primary,
    };
    final IconData icon = switch (kind) {
      StatusKind.error => Icons.error_outline_rounded,
      StatusKind.empty => Icons.inbox_outlined,
      StatusKind.loading => Icons.sync_rounded,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kind == StatusKind.loading)
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: color),
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kind == StatusKind.error ? AppColors.danger : AppColors.textPrimary,
              ),
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}