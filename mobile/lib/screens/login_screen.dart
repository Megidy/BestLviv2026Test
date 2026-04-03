import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.operatorController,
    required this.accessKeyController,
    required this.onInitialize,
  });

  final TextEditingController operatorController;
  final TextEditingController accessKeyController;
  final VoidCallback onInitialize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2A0303),
            Color(0xFF240304),
            Color(0xFF1A0304),
            Color(0xFF090607),
          ],
          stops: [0.0, 0.42, 0.78, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gapAfterTitle = constraints.maxHeight < 760 ? 70.0 : 96.0;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: SyncMark(size: 68)),
                  const SizedBox(height: 18),
                  Text(
                    'LOGISYNC',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  Text(
                    'INDUSTRIAL TERMINAL v4.2',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                  SizedBox(height: gapAfterTitle),
                  PanelCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operator Authentication',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sync with WH-04 Terminal',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        TerminalField(
                          label: 'Operator ID',
                          controller: operatorController,
                          prefixIcon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        TerminalField(
                          label: 'Access Key',
                          controller: accessKeyController,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: Icons.visibility_outlined,
                        ),
                        const SizedBox(height: 16),
                        PrimaryActionButton(
                          label: 'Initialize Sync',
                          icon: Icons.login_rounded,
                          onPressed: onInitialize,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Forgot Key',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.creamText,
                              ),
                            ),
                            Text(
                              'Emergency Bypass',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.creamText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const DecorativeDivider(),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      FooterChip(
                        label: 'NETWORK SECURE',
                        icon: Icons.shield_outlined,
                      ),
                      FooterChip(
                        label: 'SYNC READY',
                        icon: Icons.blur_circular_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SECURE INDUSTRIAL INTERFACE',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.softText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(C) 2026 LOGISYNC SYSTEMS INC.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
