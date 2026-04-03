import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FillViewportScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              Expanded(
                child: Text(
                  'INVENTORY',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          PanelCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LOGISYNC / STOCK INDEX',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.softText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inventory Terminal',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Separate inventory workspace. Resource details stay inside warehouse cards on Home.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlineActionButton(
            label: 'Back to Terminal',
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            fillWidth: true,
          ),
        ],
      ),
    );
  }
}
