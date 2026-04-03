import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({
    super.key,
    required this.onClose,
    required this.onManual,
  });

  final VoidCallback onClose;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Row(
            children: [
              SmallSquareButton(
                icon: Icons.close_rounded,
                onTap: onClose,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mutedGold,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldStroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 13,
                      color: AppColors.creamText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DEMAND_OBJECTIVE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.creamText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              const Positioned.fill(child: ScannerBackdrop()),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: ScannerFrame()),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 110,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white54,
                                    blurRadius: 18,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 78),
                            Text(
                              'ALIGN QR CODE',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Scanning for Resource ID...',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(
            children: [
              PanelCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.mutedGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.settings_input_antenna_rounded,
                        size: 18,
                        color: AppColors.creamText,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOGISYNC SCANNER v2.4',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.softText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ready for industrial input',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.greenOk,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: ScannerActionTile(
                      label: 'Flash',
                      icon: Icons.flash_on_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: ScannerActionTile(
                      label: 'Recent',
                      icon: Icons.history_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ScannerActionTile(
                      label: 'Manual',
                      icon: Icons.tune_rounded,
                      selected: true,
                      onTap: onManual,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
