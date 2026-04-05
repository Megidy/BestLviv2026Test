import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

class ShellStatusView extends StatelessWidget {
  const ShellStatusView({
    super.key,
    required this.title,
    required this.message,
    this.busy = false,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final bool busy;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: PanelCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.creamText,
                ),
              ),
              if (busy) ...[
                const SizedBox(height: 18),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.warmGold,
                  backgroundColor: AppColors.stroke,
                ),
              ],
              if (!busy && primaryLabel != null && onPrimary != null) ...[
                const SizedBox(height: 18),
                PrimaryActionButton(
                  label: primaryLabel!,
                  icon: Icons.sync_rounded,
                  onPressed: onPrimary,
                ),
              ],
              if (!busy && secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: 10),
                OutlineActionButton(
                  label: secondaryLabel!,
                  icon: Icons.logout_rounded,
                  onTap: onSecondary!,
                  fillWidth: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
