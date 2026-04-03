import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
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
                  'FACILITY MAP',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
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
